import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';
import 'package:vitals_archive/vitals_archive.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_notify/vitals_notify.dart';

import '../platform/android_usage_source.dart';
import 'app_database.dart';

/// Holds the app's state and writes every change straight through.
///
/// **Nothing is held only in memory.** A planner app that loses your day
/// because the OS reclaimed it is worse than no planner, so every mutation
/// persists before the UI is told about it.
///
/// The engines stay pure: this class reads rows, hands them to
/// [TodayPlanner] and [LedgerEngine], and writes the results back. It is the
/// only place those three meet.
class TallyController extends ChangeNotifier {
  TallyController({
    required this.db,
    required this.installId,
    this.settings = const LedgerSettings(),
    UsageSource? usageSource,
    this._notifier,
    DateTime Function()? clock,
  })  : _clock = clock ?? (() => DateTime.now().toUtc()),
        _tasks = TaskRepository(db, installId: installId),
        _projects = ProjectRepository(db, installId: installId),
        _usage = usageSource,
        _ledger = LedgerRepository(
          db,
          installId: installId,
          settings: settings,
        );

  final TallyDatabase db;
  final String installId;
  final LedgerSettings settings;

  final DateTime Function() _clock;
  final TaskRepository _tasks;
  final ProjectRepository _projects;
  final LedgerRepository _ledger;
  final UsageSource? _usage;
  final Notifier? _notifier;

  /// The id the focus alarm is scheduled under.
  ///
  /// Fixed rather than derived from the run, so a stale alarm from a block
  /// that ended badly is always cancellable by the next one.
  static const _focusAlarmId = 8801;

  /// Notifications are denied, so no end-of-block alarm can ring.
  bool focusAlarmBlocked = false;

  List<Task> tasks = const [];
  List<AppSpend> spendByApp = const [];
  List<WatchableApp> watchable = const [];
  UsageAccess usageAccess = UsageAccess.denied;
  List<PlanEntry> plan = const [];

  /// Every suggestion this install has been offered, and what became of it.
  List<SuggestionRecord> suggestionHistory = const [];

  List<Project> projects = const [];
  Map<String, int> streaks = const {};
  LedgerResult? ledger;
  FocusRun? focus;

  bool loading = true;

  DateTime get now => _clock();

  String get dayKey => _ledger.engine.dayKeyAt(now);

  /// Today, assembled for the screen.
  TodayScreenModel get today => TodayScreenModel(
        view: const TodayPlanner().buildToday(
          dayKey: dayKey,
          tasks: tasks,
          plan: plan,
          now: now,
        ),
        spendableSeconds: ledger?.spendableSeconds ?? 0,
        solvencyStreak: ledger?.currentSolvencyStreak ?? 0,
        dateLabel: _formatDate(now),
        suggestion: _suggestion(),
      );

  /// The Balance screen, from the same recomputed result Today uses.
  BalanceScreenModel get balanceModel {
    final days = ledger?.days ?? const [];
    final day = days.isNotEmpty ? days.last : null;
    // What yesterday closed at, which is what today opened with.
    final opening = days.length > 1
        ? days[days.length - 2].closingBalanceSeconds
        : 0;
    return BalanceScreenModel(
      spendableSeconds: ledger?.spendableSeconds ?? 0,
      earnedSeconds: day?.earnedSeconds ?? 0,
      spentSeconds: day?.spentSeconds ?? 0,
      savingsSeconds: ledger?.savingsSeconds ?? 0,
      solvencyStreak: ledger?.currentSolvencyStreak ?? 0,
      bestStreak: ledger?.bestSolvencyStreak ?? 0,
      graceRemainingSeconds: ledger?.graceRemainingSeconds ?? 0,
      unrepayableSeconds: day?.unrepayableSeconds ?? 0,
      spendByApp: spendByApp,
      openingSeconds: opening,
      allowanceSeconds: day?.allowanceGrantedSeconds ?? 0,
      graceUsedSeconds: day?.graceUsedSeconds ?? 0,
    );
  }

  /// Tasks not already planned into today.
  List<Task> get pool {
    final planned = {for (final entry in plan) entry.taskId};
    return [
      for (final task in tasks)
        if (!task.isArchived && !planned.contains(task.id)) task,
    ];
  }

  ManageTasksModel get manage => ManageTasksModel(
        tasks: tasks,
        now: now,
        projects: projects,
        streaks: streaks,
        plannedToday: {for (final entry in plan) entry.taskId},
      );

  // --- lifecycle -----------------------------------------------------------

  /// Loads everything and reconciles.
  ///
  /// Called on open and on resume, because the ledger is derived: whatever
  /// happened while the app was away is worked out from stored rows rather
  /// than from anything the app was keeping in its head.
  Future<void> load() async {
    // Restored before anything else, so a block that was running when the
    // process died is on screen again rather than silently lost.
    focus ??= await FocusStore.load();
    // A restored block needs its alarm back: the process died, and Android
    // does not keep notifications scheduled by a process that is gone.
    if (focus != null) await _syncFocusAlarm();
    usageAccess = await _usage?.access() ?? UsageAccess.unavailable;
    tasks = await _tasks.tasks();
    plan = await _tasks.planFor(dayKey);
    streaks = await _tasks.habitStreaks(dayKey: dayKey);
    await _loadSuggestionHistory();
    projects = await _projects.projects();
    await _reconcile();
    await loadWatchable();
    await loadGoals();
    loading = false;
    notifyListeners();
  }

  /// The installed-app list, merged with what is already watched.
  ///
  /// A watched app that has since been uninstalled stays in the list, marked,
  /// rather than vanishing: dropping it would silently stop counting something
  /// the user chose and leave its history unexplained.
  Future<void> loadWatchable() async {
    final stored = await db.select(db.watchedApps).get();
    final watchedByPackage = {
      for (final row in stored)
        if (row.deletedAt == null) row.packageName: row,
    };

    final installed = usageAccess == UsageAccess.granted
        ? await _usage?.installedApps() ?? const <InstalledApp>[]
        : const <InstalledApp>[];

    final merged = <String, WatchableApp>{};
    for (final app in installed) {
      merged[app.packageName] = WatchableApp(
        packageName: app.packageName,
        label: app.label,
        recentSeconds: app.recentSeconds,
        watching: watchedByPackage[app.packageName]?.watching ?? false,
      );
    }
    for (final row in watchedByPackage.values) {
      if (merged.containsKey(row.packageName)) continue;
      merged[row.packageName] = WatchableApp(
        packageName: row.packageName,
        label: row.label,
        recentSeconds: 0,
        watching: row.watching,
        notInstalled: true,
      );
    }

    // Watched first, then by how much time they actually cost. Someone
    // revisiting this screen is usually looking for something they already
    // picked.
    watchable = merged.values.toList()
      ..sort((a, b) {
        if (a.watching != b.watching) return a.watching ? -1 : 1;
        return b.recentSeconds.compareTo(a.recentSeconds);
      });
  }

  /// Starts or stops counting an app.
  ///
  /// Removing is never destructive: `removedAt` stops future counting from this
  /// moment only, and past statements keep the spend they already recorded.
  Future<void> setWatching(WatchableApp app, bool watching) async {
    final existing = await (db.select(db.watchedApps)
          ..where((t) => t.packageName.equals(app.packageName)))
        .getSingleOrNull();
    final stamp = now.millisecondsSinceEpoch;

    if (existing == null) {
      await db.into(db.watchedApps).insert(
            WatchedAppsCompanion.insert(
              id: Ids.newId(),
              updatedAt: stamp,
              installId: installId,
              packageName: app.packageName,
              label: app.label,
              addedAt: stamp,
              watching: Value(watching),
              notInstalled: Value(app.notInstalled),
            ),
          );
    } else {
      await (db.update(db.watchedApps)
            ..where((t) => t.packageName.equals(app.packageName)))
          .write(
        WatchedAppsCompanion(
          watching: Value(watching),
          updatedAt: Value(stamp),
          removedAt: Value(watching ? null : stamp),
        ),
      );
    }

    await loadWatchable();
    await _reconcile();
    notifyListeners();
  }

  /// Changes a ledger rule and recomputes everything under the new one.
  ///
  /// The whole history is recomputed rather than only today, because the rules
  /// are inputs to a derived ledger: changing the earn rate changes what every
  /// past day was worth, and leaving old days on the old rule would make the
  /// statement disagree with itself.
  Future<void> updateSettings(LedgerSettings next) async {
    await _saveSettings(next);
    onSettingsChanged?.call(next);
    notifyListeners();
  }

  /// Called with the new settings so the app can rebuild its controller.
  void Function(LedgerSettings)? onSettingsChanged;

  Future<void> _saveSettings(LedgerSettings next) async {
    Future<void> put(String key, String value) async {
      final existing = await (db.select(db.settings)
            ..where((t) => t.key.equals(key)))
          .getSingleOrNull();
      if (existing == null) {
        await db.into(db.settings).insert(
              SettingsCompanion.insert(
                id: Ids.newId(),
                updatedAt: now.millisecondsSinceEpoch,
                installId: installId,
                key: key,
                value: value,
              ),
            );
      } else {
        await (db.update(db.settings)..where((t) => t.key.equals(key))).write(
          SettingsCompanion(
            value: Value(value),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    }

    await put('earnRatio', '${next.earnRatio}');
    await put('dailyAllowanceMinutes', '${next.dailyAllowanceMinutes}');
    await put('dailyEarnCapMinutes', '${next.dailyEarnCapMinutes ?? -1}');
    await put('rolloverCapMinutes', '${next.rolloverCapMinutes}');
    await put('dayBoundaryHour', '${next.dayBoundaryHour}');
  }

  /// Reads the stored rules, falling back to the defaults.
  static Future<LedgerSettings> loadSettings(TallyDatabase db) async {
    final rows = await db.select(db.settings).get();
    final values = {for (final row in rows) row.key: row.value};

    int? asInt(String key) => int.tryParse(values[key] ?? '');
    const defaults = LedgerSettings();
    final cap = asInt('dailyEarnCapMinutes');

    return LedgerSettings(
      earnRatio:
          double.tryParse(values['earnRatio'] ?? '') ?? defaults.earnRatio,
      dailyAllowanceMinutes:
          asInt('dailyAllowanceMinutes') ?? defaults.dailyAllowanceMinutes,
      dailyEarnCapMinutes: cap == null
          ? defaults.dailyEarnCapMinutes
          : (cap < 0 ? null : cap),
      rolloverCapMinutes:
          asInt('rolloverCapMinutes') ?? defaults.rolloverCapMinutes,
      dayBoundaryHour: asInt('dayBoundaryHour') ?? defaults.dayBoundaryHour,
    );
  }

  /// Pulls spend from the platform, then recomputes.
  Future<void> _reconcile() async {
    final watched = await _watchedPackages();
    final source = _usage;

    if (source != null && watched.isNotEmpty) {
      final from = _ledger.engine.dayStart(dayKey);
      final spans = await source.spans(
        from: from,
        to: now,
        packages: watched,
      );
      await _storeSpend(spans, watched.toSet());
    }

    ledger = await _ledger.recomputeAndStore(
      fromDay: addDays(dayKey, -30),
      toDay: dayKey,
      now: now,
    );
    spendByApp = await _loadSpendByApp();
    await _pushSnapshot();
  }

  /// Tells the watcher where the balance stands.
  ///
  /// Pushed after every recompute, so the service's starting point is never
  /// more stale than the last time the app was open. It is also what stops the
  /// service running at all when nothing is being watched.
  Future<void> _pushSnapshot() async {
    final source = _usage;
    if (source is! AndroidUsageSource) return;

    final watched = await _watchedPackages();
    await source.updateSnapshot(
      spendableSeconds: ledger?.spendableSeconds ?? 0,
      graceSeconds: ledger?.graceRemainingSeconds ?? 0,
      asOf: now,
      packages: watched,
      dayKey: dayKey,
      notificationsEnabled: true,
    );
    await source.setWatching(
      active: watched.isNotEmpty && usageAccess == UsageAccess.granted,
    );
  }

  /// Today's spend per app, worst first.
  ///
  /// Labels come from `watched_apps` rather than from the platform, so an app
  /// uninstalled since it was watched still has a name on the statement rather
  /// than showing a bare package id.
  Future<List<AppSpend>> _loadSpendByApp() async {
    final rows = await (db.select(db.daySpend)
          ..where((t) => t.dayKey.equals(dayKey))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final watched = await db.select(db.watchedApps).get();
    final labels = {for (final app in watched) app.packageName: app};

    // The stretches behind each total, so the number can be checked rather
    // than believed. These are the same rows the ledger recomputes from.
    final spans = await (db.select(db.spendSpans)
          ..where((t) => t.dayKey.equals(dayKey))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
    final sessions = <String, List<AppSession>>{};
    for (final span in spans) {
      sessions.putIfAbsent(span.packageName, () => []).add(
            AppSession(
              startedAt: DateTime.fromMillisecondsSinceEpoch(
                span.startedAt,
                isUtc: true,
              ),
              endedAt: DateTime.fromMillisecondsSinceEpoch(
                span.endedAt,
                isUtc: true,
              ),
            ),
          );
    }

    final spend = [
      for (final row in rows)
        AppSpend(
          packageName: row.packageName,
          label: labels[row.packageName]?.label ?? row.packageName,
          seconds: row.seconds,
          notInstalled: labels[row.packageName]?.notInstalled ?? false,
          sessions: sessions[row.packageName] ?? const [],
        ),
    ]..sort((a, b) => b.seconds.compareTo(a.seconds));
    return spend;
  }

  Future<List<String>> _watchedPackages() async {
    final rows = await db.select(db.watchedApps).get();
    return [
      for (final row in rows)
        if (row.watching && row.deletedAt == null) row.packageName,
    ];
  }

  /// Replaces today's stored spans for the packages just re-read.
  ///
  /// Replaced rather than appended: the source returns the whole window every
  /// time, so appending would double-count on every reconcile.
  ///
  /// **Only the packages being refreshed are cleared.** Wiping the whole day
  /// meant that unwatching an app at 3pm deleted the time it had already cost
  /// that day, and the balance jumped up - which contradicts the rule that
  /// removing an app stops future counting and leaves history alone.
  Future<void> _storeSpend(List<UsageSpan> spans, Set<String> packages) async {
    final stamp = now.millisecondsSinceEpoch;
    final offset = now.timeZoneOffset.inMinutes;

    await db.transaction(() async {
      await (db.delete(db.spendSpans)
            ..where((t) => t.dayKey.equals(dayKey))
            ..where((t) => t.packageName.isIn(packages)))
          .go();
      for (final span in spans) {
        if (span.seconds <= 0) continue;
        await db.into(db.spendSpans).insert(
              SpendSpansCompanion.insert(
                id: Ids.newId(),
                updatedAt: stamp,
                installId: installId,
                dayKey: _ledger.engine.dayKeyAt(span.start),
                tzOffsetMinutes: offset,
                packageName: span.packageName,
                startedAt: span.start.millisecondsSinceEpoch,
                endedAt: span.end.millisecondsSinceEpoch,
              ),
            );
      }
    });
    await _ledger.rebuildDaySpend(
      fromDay: dayKey,
      toDay: dayKey,
      now: now,
    );
  }

  // --- tasks ---------------------------------------------------------------

  /// Creates a task and returns it, so the caller can plan it immediately
  /// without having to find it again by title.
  Future<Task> createTask(TaskDraft draft) async {
    final task = await _tasks.createTask(
      kind: draft.kind,
      title: draft.title,
      now: now,
      stickerId: draft.stickerId,
      estimateMinutes: draft.estimateMinutes,
      projectId: draft.projectId,
      note: draft.note,
      habitWeekdays: draft.habitWeekdays,
    );
    tasks = await _tasks.tasks();
    notifyListeners();
    return task;
  }

  Future<Project> createProject(String name, {String? stickerId}) async {
    final project = await _projects.createProject(
      name: name,
      now: now,
      stickerId: stickerId,
    );
    projects = await _projects.projects();
    notifyListeners();
    return project;
  }

  Future<void> renameProject(Project project, String name) async {
    await _projects.updateProject(project.copyWith(name: name), now: now);
    projects = await _projects.projects();
    notifyListeners();
  }

  /// Removes a project. **Its tasks survive**, unfiled.
  Future<void> deleteProject(String id) async {
    await _projects.deleteProject(id, now: now);
    projects = await _projects.projects();
    tasks = await _tasks.tasks();
    notifyListeners();
  }

  Future<void> updateTask(Task original, TaskDraft draft) async {
    await _tasks.updateTask(
      Task(
        id: original.id,
        kind: draft.kind,
        title: draft.title,
        createdAt: original.createdAt,
        stickerId: draft.stickerId,
        estimateMinutes: draft.estimateMinutes,
        projectId: original.projectId,
        habitWeekdays: draft.habitWeekdays,
        lastCompletedAt: original.lastCompletedAt,
        archivedAt: original.archivedAt,
      ),
      now: now,
    );
    tasks = await _tasks.tasks();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _tasks.deleteTask(id, now: now);
    tasks = await _tasks.tasks();
    plan = await _tasks.planFor(dayKey);
    notifyListeners();
  }

  // --- the day -------------------------------------------------------------

  Future<void> addToToday(List<String> taskIds, {PlanSource? source}) async {
    plan = const TodayPlanner().addToDay(
      dayKey: dayKey,
      plan: plan,
      taskIds: taskIds,
      source: source ?? PlanSource.manual,
    );
    await _savePlan();
  }

  Future<void> toggle(PlanEntry entry) async {
    const planner = TodayPlanner();

    if (entry.isDone) {
      plan = planner
          .uncomplete(plan: plan, stamps: const [], entryId: entry.id)
          .plan;
      await _tasks.removeStampsFor(
        taskId: entry.taskId,
        dayKey: dayKey,
        now: now,
      );
    } else {
      final result = planner.complete(
        plan: plan,
        entryId: entry.id,
        tasks: tasks,
        at: now,
        dayKey: dayKey,
      );
      plan = result.plan;
      if (result.stamp != null) {
        await _tasks.addStamp(result.stamp!, now: now);
      }
    }

    await _savePlan();
    streaks = await _tasks.habitStreaks(dayKey: dayKey);
    notifyListeners();
  }

  Future<void> reorder(int from, int to) async {
    plan = const TodayPlanner().reorder(
      dayKey: dayKey,
      plan: plan,
      fromIndex: from,
      toIndex: to,
    );
    await _savePlan();
  }

  Future<void> _savePlan() async {
    await _tasks.savePlan(dayKey: dayKey, entries: plan, now: now);
    plan = await _tasks.planFor(dayKey);
    notifyListeners();
  }

  /// Burns savings on something off-screen.
  ///
  /// Written as a treat row and then recomputed, so the engine applies its own
  /// rule: the minutes leave the system entirely and cannot return as scroll
  /// time under any sequence of transfers.
  Future<void> treatYourself(String label, int seconds) async {
    if (seconds <= 0) return;
    await db.into(db.treats).insert(
          TreatsCompanion.insert(
            id: Ids.newId(),
            updatedAt: now.millisecondsSinceEpoch,
            installId: installId,
            dayKey: dayKey,
            tzOffsetMinutes: now.timeZoneOffset.inMinutes,
            minutesBurned: (seconds / 60).floor(),
            label: label,
          ),
        );
    ledger = await _ledger.recomputeAndStore(
      fromDay: addDays(dayKey, -30),
      toDay: dayKey,
      now: now,
    );
    await _pushSnapshot();
    notifyListeners();
  }

  // --- focus ---------------------------------------------------------------

  void startFocus({String? taskId, int minutes = 25}) {
    focus = FocusRun(
      id: Ids.newId(),
      startedAt: now,
      planned: Duration(minutes: minutes),
      taskId: taskId,
    );
    _saveFocus();
    notifyListeners();
  }

  void pauseFocus() {
    focus = focus?.pause(now);
    _saveFocus();
    notifyListeners();
  }

  void resumeFocus() {
    focus = focus?.resume(now);
    _saveFocus();
    notifyListeners();
  }

  void extendFocus(Duration by) {
    focus = focus?.extend(by);
    _saveFocus();
    notifyListeners();
  }

  /// Keeps a running block across process death.
  ///
  /// The wall-clock design already survives backgrounding, but not the OS
  /// reclaiming the process - and on the cheap phones this audience owns that
  /// happens constantly. Losing a 45 minute block because Android needed the
  /// memory is the worst failure this app has, because the time really was
  /// spent.
  Future<void> _saveFocus() async {
    await FocusStore.save(focus);
    await _syncFocusAlarm();
  }

  /// Keeps the end-of-block alarm in step with the run.
  ///
  /// The reason this exists: a focus block is most useful when the phone is
  /// being used for the thing being focused on. Studying on the same phone
  /// means leaving Tally's screen, and a countdown nobody is looking at is not
  /// a timer. Without this, the only way to know a block had finished was to
  /// come back and check, which defeats the block.
  ///
  /// Rescheduled from scratch on every transition rather than adjusted:
  /// pausing, resuming and extending all move the end, and one cancel-then-set
  /// has no states to get wrong.
  Future<void> _syncFocusAlarm() async {
    final notifier = _notifier;
    if (notifier == null) return;

    await notifier.cancel(_focusAlarmId);

    final run = focus;
    // Nothing to ring for: no block, a finished one, or one sitting paused
    // with no end time to aim at.
    if (run == null || !run.isRunning || run.isPaused) return;

    // Checked every time a block starts rather than once at onboarding: the
    // permission can be revoked from system settings at any point, and an
    // alarm that cannot ring must be reported before the block, not after it.
    final permission = await notifier.permission();
    final blocked = permission != NotificationPermission.granted;
    if (blocked != focusAlarmBlocked) {
      focusAlarmBlocked = blocked;
      notifyListeners();
    }
    if (blocked) return;

    final endsAt = now.add(Duration(seconds: run.remainingSeconds(now)));
    await notifier.schedule(
      Nudge(
        id: _focusAlarmId,
        // The user set this timer, so it is [NudgeKind.scheduled]: never
        // capped by the nudge budget and never held back by quiet hours.
        // Silently dropping a timer someone started is a broken app.
        kind: NudgeKind.scheduled,
        title: 'Time is up',
        body: run.target.inMinutes >= 60
            ? 'Your ${run.target.inHours} hour block is done.'
            : 'Your ${run.target.inMinutes} minute block is done.',
        at: endsAt,
        tag: 'focus-end',
        quietHoursExempt: true,
      ),
    );
  }

  /// Ends the block and banks whatever was worked.
  ///
  /// Giving up and finishing are the same path: both produce a session of the
  /// length actually focused, and the engine applies its usual rules. A block
  /// under the earning floor simply earns nothing, with nothing said about it.
  Future<void> endFocus() async {
    final run = focus?.finish(now);
    focus = null;
    await FocusStore.clear();
    await _notifier?.cancel(_focusAlarmId);
    if (run == null) {
      notifyListeners();
      return;
    }

    final session = run.toSession(now);
    if (session != null) {
      await _tasks.addSession(session, dayKey: dayKey, now: now);
      ledger = await _ledger.recomputeAndStore(
        fromDay: addDays(dayKey, -30),
        toDay: dayKey,
        now: now,
      );
    }
    notifyListeners();
  }

  /// Builds a statement for [period], with the period before it to compare
  /// against.
  ///
  /// Reads stored `day_ledger` rows rather than recomputing, which is what
  /// keeps a year view fast. The comparison period is the same length
  /// immediately before, so "vs before" always means a like-for-like span.
  Future<StatementModel> statement(StatementPeriod period) async {
    final toDay = dayKey;
    final fromDay = addDays(toDay, -(period.days - 1));
    final prevTo = addDays(fromDay, -1);
    final prevFrom = addDays(prevTo, -(period.days - 1));

    final rollups = await _rollups(fromDay, toDay);
    final previous = await _rollups(prevFrom, prevTo);

    final spend = await (db.select(db.daySpend)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final watched = await db.select(db.watchedApps).get();
    final labels = {for (final app in watched) app.packageName: app};

    final byApp = <String, int>{};
    for (final row in spend) {
      byApp.update(
        row.packageName,
        (v) => v + row.seconds,
        ifAbsent: () => row.seconds,
      );
    }

    final sessions = await (db.select(db.sessions)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final byTask = <String, int>{};
    for (final row in sessions) {
      final key = row.taskId ?? '';
      byTask.update(
        key,
        (v) => v + (row.endedAt - row.startedAt) ~/ 1000,
        ifAbsent: () => (row.endedAt - row.startedAt) ~/ 1000,
      );
    }
    final titles = {for (final task in tasks) task.id: task};

    final treatRows = await (db.select(db.treats)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull()))
        .get();

    return StatementModel(
      period: period,
      days: rollups,
      previousEarnedSeconds:
          previous.fold(0, (a, d) => a + d.earnedSeconds),
      previousSpentSeconds: previous.fold(0, (a, d) => a + d.spentSeconds),
      savingsSeconds: ledger?.savingsSeconds ?? 0,
      spendByApp: [
        for (final entry in byApp.entries)
          AppSpendLine(
            label: labels[entry.key]?.label ?? entry.key,
            seconds: entry.value,
            notInstalled: labels[entry.key]?.notInstalled ?? false,
          ),
      ]..sort((a, b) => b.seconds.compareTo(a.seconds)),
      earnByTask: [
        for (final entry in byTask.entries)
          TaskEarn(
            // A session with no task is still time focused, and hiding it
            // would make the two columns disagree.
            title: titles[entry.key]?.title ?? 'Unattached focus',
            seconds: entry.value,
            stickerId: titles[entry.key]?.stickerId,
          ),
      ]..sort((a, b) => b.seconds.compareTo(a.seconds)),
      treats: [
        for (final row in treatRows)
          TreatTaken(
            label: row.label,
            minutesBurned: row.minutesBurned,
            dayKey: row.dayKey,
          ),
      ],
    );
  }

  List<Goal> goals = const [];

  /// Loads goals, with any linked project's real hours attached.
  Future<void> loadGoals() async {
    final rows = await (db.select(db.goals)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final sessions = await (db.select(db.sessions)
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final byProject = <String, (int count, int seconds)>{};
    for (final row in sessions) {
      final task = tasks.where((t) => t.id == row.taskId).firstOrNull;
      final project = task?.projectId ?? task?.id;
      if (project == null) continue;
      final seconds = (row.endedAt - row.startedAt) ~/ 1000;
      final current = byProject[project] ?? (0, 0);
      byProject[project] = (current.$1 + 1, current.$2 + seconds);
    }

    goals = [
      for (final row in rows)
        Goal(
          id: row.id,
          scope: row.scope == 'life' ? GoalScope.life : GoalScope.year,
          title: row.title,
          note: row.note,
          linkedProjectTitle: row.linkedProjectId == null
              ? null
              : tasks
                  .where((t) => t.id == row.linkedProjectId)
                  .firstOrNull
                  ?.title,
          linkedSessions: byProject[row.linkedProjectId]?.$1 ?? 0,
          linkedSeconds: byProject[row.linkedProjectId]?.$2 ?? 0,
          achievedAt: row.achievedAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  row.achievedAt!,
                  isUtc: true,
                ),
        ),
    ];
    notifyListeners();
  }

  Future<void> saveGoal({
    required GoalScope scope,
    required String title,
    String? note,
    String? existingId,
  }) async {
    final stamp = now.millisecondsSinceEpoch;
    if (existingId == null) {
      await db.into(db.goals).insert(
            GoalsCompanion.insert(
              id: Ids.newId(),
              updatedAt: stamp,
              installId: installId,
              scope: scope.name,
              title: title,
              createdAt: stamp,
              note: Value(note),
            ),
          );
    } else {
      await (db.update(db.goals)..where((t) => t.id.equals(existingId))).write(
        GoalsCompanion(
          title: Value(title),
          note: Value(note),
          updatedAt: Value(stamp),
        ),
      );
    }
    await loadGoals();
  }

  Future<void> achieveGoal(String id) async {
    final stamp = now.millisecondsSinceEpoch;
    await (db.update(db.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(achievedAt: Value(stamp), updatedAt: Value(stamp)),
    );
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    final stamp = now.millisecondsSinceEpoch;
    await (db.update(db.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(deletedAt: Value(stamp), updatedAt: Value(stamp)),
    );
    await loadGoals();
  }

  /// Builds the backup archive.
  Future<Uint8List> exportArchive({required String appVersion}) =>
      TallyBackup(db).export(
        appVersion: appVersion,
        installId: installId,
        exportedAtMillis: now.millisecondsSinceEpoch,
        timezone: DateTime.now().timeZoneName,
        dayBoundaryHour: settings.dayBoundaryHour,
      );

  /// Reads an archive without writing anything, so the user can be shown what
  /// they are about to replace.
  ({ImportPreview? preview, ArchiveError? error}) previewArchive(
    Uint8List bytes,
  ) {
    final read = const ArchiveReader().read(
      bytes,
      appSchemaVersion: db.schemaVersion,
    );
    if (read.error != null) return (preview: null, error: read.error);
    return (
      preview: const ImportPlanner().preview(read.contents!),
      error: null,
    );
  }

  /// Restores, then checks the imported history by recomputing it.
  ///
  /// The verification is what makes a restore trustworthy, and in an app that
  /// already recomputes it is free: it exercises the exporter, the importer and
  /// the engine at once on the user's real data.
  Future<({ImportVerification? verification, ArchiveError? error})>
      restoreArchive(Uint8List bytes) async {
    final result = await TallyBackup(db).import(bytes);
    if (result.error != null) {
      return (verification: null, error: result.error);
    }

    final verification = await _ledger.verifyImported(now: now);

    // Usage checkpoints never travel, so reconciliation restarts from this
    // moment on this device. Everything before is frozen history.
    await load();
    return (verification: verification, error: null);
  }

  /// The numbers as a spreadsheet, for the period shown.
  Future<String> exportCsv(StatementPeriod period, {bool perApp = false}) =>
      CsvExport(db).build(
        fromDay: addDays(dayKey, -(period.days - 1)),
        toDay: dayKey,
        includePerApp: perApp,
      );

  /// This month's stamps.
  Future<StickerSheetModel> stickerSheet() async {
    final local = now.toLocal();
    final first = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-01';
    final daysInMonth = DateTime(local.year, local.month + 1, 0).day;
    final last = addDays(first, daysInMonth - 1);

    final rows = await (db.select(db.stickerStamps)
          ..where((t) => t.dayKey.isBetweenValues(first, last))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.stampedAt)]))
        .get();

    return StickerSheetModel(
      monthLabel: '${_months[local.month - 1]} ${local.year}',
      daysInMonth: daysInMonth,
      daysElapsed: local.day,
      stamps: [
        for (final row in rows)
          StickerStamp(
            id: row.id,
            dayKey: row.dayKey,
            stickerId: row.stickerId,
            taskId: row.taskId,
            at: DateTime.fromMillisecondsSinceEpoch(
              row.stampedAt,
              isUtc: true,
            ),
          ),
      ],
    );
  }

  /// What the user is actually like: when they start, what they focus on.
  ///
  /// Built from sessions rather than rollups, because the questions here are
  /// about individual blocks - the hour one began, how long the longest ran -
  /// which a day total cannot answer.
  Future<InsightsModel> insights({int weeks = 8}) async {
    final toDay = dayKey;
    final fromDay = addDays(toDay, -(weeks * 7 - 1));

    final rows = await (db.select(db.sessions)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final hours = List<int>.filled(24, 0);
    var phoneDown = 0;
    var longest = 0;
    final byWeek = <int, int>{};
    final byTask = <String, int>{};

    for (final row in rows) {
      final seconds = (row.endedAt - row.startedAt) ~/ 1000;
      if (seconds > longest) longest = seconds;
      if (row.phoneDownVerified) phoneDown += seconds;

      // The local hour, because "when do I start" is a question about the
      // user's day rather than about UTC.
      final startedLocal =
          DateTime.fromMillisecondsSinceEpoch(row.startedAt).toLocal();
      hours[startedLocal.hour] += 1;

      final weekIndex = daysBetween(fromDay, row.dayKey) ~/ 7;
      byWeek.update(weekIndex, (v) => v + seconds, ifAbsent: () => seconds);

      final key = row.taskId ?? '';
      byTask.update(key, (v) => v + seconds, ifAbsent: () => seconds);
    }

    final titles = {for (final task in tasks) task.id: task};
    final rollups = await _rollups(fromDay, toDay);

    return InsightsModel(
      weeks: [
        for (var i = 0; i < weeks; i++)
          Bar(
            // Counted back from now, so the rightmost bar is always this week.
            label: i == weeks - 1 ? 'now' : '-${weeks - 1 - i}',
            seconds: byWeek[i] ?? 0,
          ),
      ],
      hourHistogram: hours,
      byCategory: [
        for (final entry in byTask.entries)
          Slice(
            label: titles[entry.key]?.title ?? 'Unattached focus',
            seconds: entry.value,
            stickerId: titles[entry.key]?.stickerId,
          ),
      ]..sort((a, b) => b.seconds.compareTo(a.seconds)),
      phoneDownSeconds: phoneDown,
      longestBlockSeconds: longest,
      dreadCleared: tasks
          .where((t) => t.kind == TaskKind.dread && t.lastCompletedAt != null)
          .length,
      emptyDays: rollups
          .where((d) => d.earnedSeconds == 0 && d.spentSeconds == 0)
          .length,
      totalDays: rollups.length,
    );
  }

  /// Derives what has been unlocked, from history rather than from a flag.
  ///
  /// Recomputed every time, on the same rule as the ledger: a stored flag can
  /// drift, and a restored backup has to rebuild the right collection from the
  /// imported rows rather than trusting a boolean written by an older version.
  Future<UnlockContext> unlockContext() async {
    final sessions = await (db.select(db.sessions)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final rollups = await db.select(db.dayLedger).get();
    final treatRows = await (db.select(db.treats)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final meta = await db.select(db.appMeta).getSingleOrNull();

    var longestSession = 0;
    var phoneDown = 0;
    var longestPhoneDown = 0;
    var earlyBird = false;
    var nightOwl = false;
    var phoneDownMorning = false;
    var phoneDownNight = false;

    for (final row in sessions) {
      final seconds = (row.endedAt - row.startedAt) ~/ 1000;
      final minutes = seconds ~/ 60;
      if (minutes > longestSession) longestSession = minutes;

      final startLocal =
          DateTime.fromMillisecondsSinceEpoch(row.startedAt).toLocal();
      if (startLocal.hour < 7) earlyBird = true;
      if (startLocal.hour >= 22) nightOwl = true;

      if (row.phoneDownVerified) {
        phoneDown++;
        if (minutes > longestPhoneDown) longestPhoneDown = minutes;
        if (startLocal.hour < 9) phoneDownMorning = true;
        if (startLocal.hour >= 21) phoneDownNight = true;
      }
    }

    var bestStreak = 0;
    var run = 0;
    var largestDebtCleared = 0;
    final sorted = rollups.toList()
      ..sort((a, b) => a.dayKey.compareTo(b.dayKey));
    for (final day in sorted) {
      run = day.solvent ? run + 1 : 0;
      if (run > bestStreak) bestStreak = run;
      final cleared = day.allowanceToDebtSeconds ~/ 60;
      if (cleared > largestDebtCleared) largestDebtCleared = cleared;
    }

    var peakSavings = 0;
    for (final day in sorted) {
      final saved = day.closingSavingsSeconds ~/ 60;
      if (saved > peakSavings) peakSavings = saved;
    }

    var largestTreat = 0;
    for (final treat in treatRows) {
      if (treat.minutesBurned > largestTreat) {
        largestTreat = treat.minutesBurned;
      }
    }

    final installedAt = meta == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(meta.installedAt, isUtc: true);

    final dread = tasks.where((t) => t.kind == TaskKind.dread).toList();
    final clearedDread =
        dread.where((t) => t.lastCompletedAt != null).length;

    return UnlockContext(
      bestSolvencyStreak: bestStreak,
      largestDebtClearedMinutes: largestDebtCleared,
      phoneDownBlocks: phoneDown,
      longestPhoneDownMinutes: longestPhoneDown,
      phoneDownBefore9am: phoneDownMorning,
      phoneDownAfter9pm: phoneDownNight,
      treatCount: treatRows.length,
      largestTreatMinutes: largestTreat,
      peakSavingsMinutes: peakSavings,
      dreadCleared: clearedDread,
      sessionCount: sessions.length,
      longestSessionMinutes: longestSession,
      startedBefore7am: earlyBird,
      startedAfter10pm: nightOwl,
      bestHabitStreak: streaks.values.fold(0, (m, v) => v > m ? v : m),
      daysSinceInstall: now.difference(installedAt).inDays,
    );
  }

  /// Stored rollups for a range, with missing days filled in as zero rows.
  ///
  /// The heatmap and every run-length calculation need one cell per day, so a
  /// gap has to be a zero rather than an absence.
  Future<List<DayRollup>> _rollups(String fromDay, String toDay) async {
    final rows = await (db.select(db.dayLedger)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final byDay = {for (final row in rows) row.dayKey: row};

    return [
      for (final key in dayKeyRange(fromDay, toDay))
        if (byDay[key] case final row?)
          DayRollup(
            dayKey: row.dayKey,
            allowanceGrantedSeconds: row.allowanceGrantedSeconds,
            allowanceToDebtSeconds: row.allowanceToDebtSeconds,
            earnedSeconds: row.earnedSeconds,
            earnCappedSeconds: row.earnCappedSeconds,
            spentSeconds: row.spentSeconds,
            graceUsedSeconds: row.graceUsedSeconds,
            unrepayableSeconds: row.unrepayableSeconds,
            closingBalanceSeconds: row.closingBalanceSeconds,
            closingSavingsSeconds: row.closingSavingsSeconds,
            overflowToSavingsSeconds: row.overflowToSavingsSeconds,
            treatedSeconds: row.treatedSeconds,
            solvent: row.solvent,
          )
        else
          DayRollup(
            dayKey: key,
            allowanceGrantedSeconds: 0,
            allowanceToDebtSeconds: 0,
            earnedSeconds: 0,
            earnCappedSeconds: 0,
            spentSeconds: 0,
            graceUsedSeconds: 0,
            unrepayableSeconds: 0,
            closingBalanceSeconds: 0,
            closingSavingsSeconds: 0,
            overflowToSavingsSeconds: 0,
            treatedSeconds: 0,
            // A day with nothing recorded closed at zero, which is solvent.
            solvent: true,
          ),
    ];
  }

  // --- helpers -------------------------------------------------------------

  LibraryItem? _suggestion() => const SuggestionPicker().suggestionFor(
        dayKey: dayKey,
        installId: installId,
        library: shippedLibrary,
        // The history is what makes "not now" and "add" mean anything: the
        // picker suppresses accepted items forever and dismissed ones for its
        // repeat window, and it can only do that if it is told.
        //
        // This used to pass `addedItemIds: {task.id for tasks}`, comparing
        // task UUIDs against library item ids. Two id spaces that never
        // intersect, so nothing was ever suppressed and the same suggestion
        // came back day after day however many times it was accepted.
        history: suggestionHistory,
      );

  /// Records the fate of today's suggestion and picks the next one.
  ///
  /// Both buttons land here. "Not now" wrote nothing at all before, which is
  /// why it looked like a button that did nothing: the card was rebuilt from
  /// the same deterministic pick a moment later.
  Future<void> _recordSuggestion(
    LibraryItem item,
    SuggestionOutcome outcome,
  ) async {
    await db.into(db.suggestionHistory).insert(
          SuggestionHistoryCompanion.insert(
            id: Ids.newId(),
            updatedAt: now.millisecondsSinceEpoch,
            installId: installId,
            dayKey: dayKey,
            tzOffsetMinutes: now.timeZoneOffset.inMinutes,
            itemId: item.id,
            outcome: outcome.name,
          ),
        );
    await _loadSuggestionHistory();
    notifyListeners();
  }

  /// Turns down today's suggestion. Another one takes its place immediately.
  Future<void> dismissSuggestion(LibraryItem item) =>
      _recordSuggestion(item, SuggestionOutcome.dismissed);

  /// Accepts today's suggestion: it becomes a real task, planned into today.
  ///
  /// The task and the history row are written together so the card cannot be
  /// replaced by a copy of itself if something fails in between.
  Future<void> acceptSuggestion(LibraryItem item) async {
    final task = await createTask(
      TaskDraft(
        kind: TaskKind.oneoff,
        title: item.title,
        stickerId: item.stickerId,
        estimateMinutes: item.minutes,
      ),
    );
    await addToToday([task.id], source: PlanSource.suggestion);
    await _recordSuggestion(item, SuggestionOutcome.accepted);
  }

  Future<void> _loadSuggestionHistory() async {
    final rows = await (db.select(db.suggestionHistory)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    suggestionHistory = [
      for (final row in rows)
        SuggestionRecord(
          itemId: row.itemId,
          dayKey: row.dayKey,
          outcome: SuggestionOutcome.values.firstWhere(
            (o) => o.name == row.outcome,
            // An outcome written by a newer version is not a reason to crash a
            // launch. Treated as merely offered, which suppresses nothing.
            orElse: () => SuggestionOutcome.offered,
          ),
        ),
    ];
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  static const _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static String _formatDate(DateTime utc) {
    final local = utc.toLocal();
    return '${_days[local.weekday - 1]} ${local.day} '
        '${_months[local.month - 1]}';
  }
}
