import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';
import 'package:vitals_archive/vitals_archive.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_notify/vitals_notify.dart';

import '../platform/android_focus_notice.dart';
import '../platform/android_home_widget.dart';
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
    Notifier? notifier,
    AndroidHomeWidget? homeWidget,
    AndroidFocusNotice? focusNotice,
    DateTime Function()? clock,
    // Assigned rather than declared as initialising formals: `this._field` in
    // a named parameter list does not stay named, and callers end up having to
    // pass it positionally.
  })  :
        // ignore: prefer_initializing_formals
        _notifier = notifier,
        // ignore: prefer_initializing_formals
        _homeWidget = homeWidget,
        // ignore: prefer_initializing_formals
        _focusNotice = focusNotice,
        _clock = clock ?? (() => DateTime.now().toUtc()),
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
  final AndroidHomeWidget? _homeWidget;
  final AndroidFocusNotice? _focusNotice;

  /// The id the focus alarm is scheduled under.
  ///
  /// Fixed rather than derived from the run, so a stale alarm from a block
  /// that ended badly is always cancellable by the next one.
  static const _focusAlarmId = 8801;

  /// Notifications are denied, so no end-of-block alarm can ring.
  bool focusAlarmBlocked = false;

  /// The alarm will ring, but Android may hold it for minutes.
  ///
  /// A separate flag from [focusAlarmBlocked] because it is a separate
  /// switch with a separate fix, and because the two need different words:
  /// one is "nothing will ring", this one is "it may ring late".
  bool focusAlarmImprecise = false;

  bool _askedForNotifications = false;

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
  Future<void> _load() async {
    // Restored before anything else, so a block that was running when the
    // process died is on screen again rather than silently lost.
    focus ??= await FocusStore.load(now: now);
    // A restored block needs its alarm back: the process died, and Android
    // does not keep notifications scheduled by a process that is gone.
    if (focus != null) await _syncFocusAlarm();
    usageAccess = await _usage?.access() ?? UsageAccess.unavailable;
    // Before anything reads the task list: a line captured from the home
    // screen is a task the user has already written down, and it should be
    // there the first time they look rather than after the next reload.
    await _drainCaptures();
    tasks = await _tasks.tasks();
    plan = await _tasks.planFor(dayKey);
    await _planCaptured();
    await _planRecurring();
    await _settleExpiredFocus();
    // After the task list is read, so a restored block can be named rather than
    // saying "Focusing" at someone who knows exactly what they started.
    await _syncFocusNotice();
    streaks = await _tasks.habitStreaks(dayKey: dayKey);
    await _loadSuggestionHistory();
    projects = await _projects.projects();
    await _reconcile();
    await loadWatchable();
    await loadGoals();
  }

  /// Loads, and guarantees the app leaves its blank loading state.
  ///
  /// `build` renders nothing at all while [loading] is true, so **any** step
  /// of [_load] throwing used to leave the user on an empty screen with no
  /// route out but reinstalling. A step that fails costs its own feature; it
  /// must not cost the app.
  Future<void> load() async {
    try {
      await _load();
    } finally {
      loading = false;
      notifyListeners();
    }
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

  /// Takes the user to the OS switch for exact alarms, then re-arms.
  ///
  /// Re-arming matters: the alarm already scheduled for the running block was
  /// registered as inexact, and that does not change retroactively. Without
  /// the reschedule, granting the permission would fix every future block and
  /// not the one the user is sitting in front of.
  Future<void> requestExactAlarms() async {
    final notifier = _notifier;
    if (notifier == null) return;
    await notifier.requestExactScheduling();
    await _syncFocusAlarm();
  }

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
    await _pushWidget();
  }

  /// Redraws the home screen widget.
  ///
  /// Pushed after every recompute, so the widget is never showing a number the
  /// app has already moved past. Since the balance notice and its background
  /// service were removed, this is the only writer of the widget's minutes:
  /// they are correct as of the last time the app was open and go stale after
  /// that rather than ticking on their own. It is also the only push: ticking a
  /// task recomputes, and everything that changes the plan goes through the
  /// same path.
  Future<void> _pushWidget() async {
    final widget = _homeWidget;
    if (widget == null) return;
    await widget.push(
      view: today.view,
      dateLabel: _formatDate(now),
      spendableSeconds: ledger?.spendableSeconds ?? 0,
      // A confident zero would be a claim the app cannot make without usage
      // access, so the widget simply says nothing about minutes instead.
      usageVisible: usageAccess == UsageAccess.granted,
      validUntil: _ledger.engine.dayStart(addDays(dayKey, 1)),
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
      repeat: draft.repeat,
      habitWeekdays: draft.habitWeekdays,
    );
    tasks = await _tasks.tasks();
    // A habit written this morning belongs on this morning's list. Waiting for
    // the next load would mean creating a daily task and watching today stay
    // unchanged, which reads as the repeat setting not having taken.
    await _planRecurring();
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
      // Built field by field rather than copied, which is why the note went
      // missing here: a field added to Task is silently dropped by every
      // constructor call that was written before it existed, and nothing
      // fails. Anything the draft owns is taken from the draft, anything it
      // does not is taken from the original.
      Task(
        id: original.id,
        kind: draft.kind,
        title: draft.title,
        createdAt: original.createdAt,
        repeat: draft.repeat,
        note: draft.note,
        // Opening the sheet and saving **is** the act of sorting, so it clears
        // the flag rather than needing a separate "sorted" button. Anything
        // else would leave things in the inbox that the user had already dealt
        // with, which is how an inbox stops being trusted.
        needsSorting: false,
        stickerId: draft.stickerId,
        estimateMinutes: draft.estimateMinutes,
        projectId: draft.projectId ?? original.projectId,
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
    // Before anything reads the task list: a line captured from the home
    // screen is a task the user has already written down, and it should be
    // there the first time they look rather than after the next reload.
    await _drainCaptures();
    tasks = await _tasks.tasks();
    plan = await _tasks.planFor(dayKey);
    await _planCaptured();
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
    await _syncFocusNotice();
  }

  /// Keeps the countdown in the shade in step with the run.
  ///
  /// Rebuilt on every transition for the same reason as the alarm: pausing,
  /// resuming and extending all move the end, and one post-or-cancel has no
  /// states to get wrong.
  ///
  /// Cheap to repost - Android replaces the notification by id and the digits
  /// are ticked by SystemUI from the end instant, so there is no timer here and
  /// nothing to keep alive between transitions.
  Future<void> _syncFocusNotice() async {
    final notice = _focusNotice;
    if (notice == null) return;

    final run = focus;
    if (run == null || !run.isRunning) {
      await notice.hide();
      return;
    }

    await notice.show(
      run: run,
      now: now,
      taskTitle: run.taskId == null
          ? null
          : tasks.where((t) => t.id == run.taskId).firstOrNull?.title,
    );
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

    final run = focus;

    // **Checked before the cancel, because `cancel` also takes down a
    // notification that has already been shown.**
    //
    // A block restored from storage can be past its end: the alarm has just
    // rung, or is ringing as this runs, and opening the app is exactly what
    // someone does when it does. Cancelling here wiped the ring off the
    // screen a moment after it arrived, so the block looked like it had
    // never finished. Nothing needs re-arming either - the instant has gone,
    // and settling the block is a later step of [load].
    if (run != null && run.isRunning && run.remainingSeconds(now) <= 0) return;

    await notifier.cancel(_focusAlarmId);

    // Nothing to ring for: no block, a finished one, or one sitting paused
    // with no end time to aim at.
    if (run == null || !run.isRunning || run.isPaused) return;

    // Checked every time a block starts rather than once at onboarding: the
    // permission can be revoked from system settings at any point, and an
    // alarm that cannot ring must be reported before the block, not after it.
    var permission = await notifier.permission();

    // Asked again here, once per run of the app, when a block is actually
    // starting. Onboarding asks too, but someone who said no then - or who
    // never saw that step because they installed an earlier build - would
    // otherwise have a timer that silently never rings. Android shows nothing
    // if the answer is already a permanent no, so this cannot become nagging.
    if (permission != NotificationPermission.granted && !_askedForNotifications) {
      _askedForNotifications = true;
      permission = await notifier.requestPermission();
    }

    final blocked = permission != NotificationPermission.granted;
    if (blocked != focusAlarmBlocked) {
      focusAlarmBlocked = blocked;
      notifyListeners();
    }
    if (blocked) return;

    // Asked every time, because it is revocable from system settings and
    // because it is **off by default**: from Android 14 an app targeting a
    // recent SDK does not get exact alarms until the user grants them, so
    // the untouched state of every fresh install is a timer Android may
    // deliver minutes late.
    final exact = await notifier.canScheduleExactly();
    if (exact == focusAlarmImprecise) {
      focusAlarmImprecise = !exact;
      notifyListeners();
    }

    final endsAt = now.add(Duration(seconds: run.remainingSeconds(now)));
    await notifier.schedule(
      Nudge(
        id: _focusAlarmId,
        // The user set this timer, so it is [NudgeKind.alarm]: never capped
        // by the nudge budget, never held back by quiet hours, and rung on
        // the alarm stream. A block ends with the phone face down and the
        // ringer low - that is the point of it - so a notification at
        // notification volume is one you are meant to miss.
        kind: NudgeKind.alarm,
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

  /// Finishes a block whose time ran out while the app was away.
  ///
  /// The alarm rings on time, but ringing is all it does: the notification is
  /// posted by Android from a receiver, with no Dart running behind it. Until
  /// now the block was only *settled* by [FocusScreen] noticing the countdown
  /// had reached zero, which needs the app open on that screen. So the timer
  /// went off, the user put the phone down, and the task sat unticked until
  /// they came back and ticked it by hand - having already done the work.
  ///
  /// Run on every load, after the plan is read, because [endFocus] ticks a plan
  /// entry and cannot do that before there is a plan. Paused blocks are left
  /// alone: [FocusRun.isComplete] is false while paused, so a block paused
  /// overnight is still waiting rather than finished.
  Future<void> _settleExpiredFocus() async {
    final run = focus;
    if (run == null || !run.isRunning) return;
    final completedAt = run.completedAt(now);
    if (completedAt == null) return;
    // Settled at the instant the clock ran out, not at the instant the app was
    // reopened. Otherwise a one hour block left overnight banks nine hours.
    await endFocus(at: completedAt);
  }

  /// Ends the block and banks whatever was worked.
  ///
  /// Giving up and finishing are the same path: both produce a session of the
  /// length actually focused, and the engine applies its usual rules. A block
  /// under the earning floor simply earns nothing, with nothing said about it.
  /// [at] is when the block ended, defaulting to now.
  ///
  /// Passed explicitly only when settling a block that ran out while the app
  /// was closed: the seconds credited are the seconds focused, and those ended
  /// when the timer did.
  Future<void> endFocus({DateTime? at}) async {
    final endedAt = at ?? now;
    final run = focus?.finish(endedAt);
    focus = null;
    await FocusStore.clear();

    // **A block that ran its full length keeps its alarm.**
    //
    // The alarm is due at the very instant the block completes, and this
    // method is reached at that same instant when the app is still alive in
    // the background - the countdown keeps ticking there. Cancelling here
    // beat the OS to it by a few milliseconds and killed the ring: the timer
    // worked when Android had already killed the process and failed when it
    // had not, which is the worst possible way for a timer to behave.
    //
    // Ending early is the opposite case: nothing has finished, and an alarm
    // for a block the user abandoned must not ring.
    if (run == null || !run.isComplete(endedAt)) {
      await _notifier?.cancel(_focusAlarmId);
    }
    await _focusNotice?.hide();
    if (run == null) {
      notifyListeners();
      return;
    }

    final session = run.toSession(endedAt);
    if (session != null) {
      await _tasks.addSession(session, dayKey: dayKey, now: now);
      ledger = await _ledger.recomputeAndStore(
        fromDay: addDays(dayKey, -30),
        toDay: dayKey,
        now: now,
      );
    }

    // A block that ran its full length ticks the task it was for.
    //
    // Only on completion, never on giving up: the first is the user saying
    // they did the thing, the second is them saying they did not. Routed
    // through [toggle] rather than writing the plan directly, so the sticker
    // is stamped and the streak recomputed exactly as if it had been ticked by
    // hand - two paths to "done" that leave different state behind is how the
    // second currency quietly stops matching the first.
    if (run.isComplete(endedAt) && run.taskId != null) {
      final entry = plan
          .where((e) => e.taskId == run.taskId && !e.isDone)
          .firstOrNull;
      if (entry != null) await toggle(entry);
    }

    // The widget shows the plan and the balance, and this changed both.
    await _pushWidget();
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

  /// Turns anything captured from the home screen into real tasks.
  ///
  /// They arrive as [TaskKind.oneoff] and marked [Task.needsSorting], which is
  /// the honest description of what was captured: a thing to do, with nobody
  /// having yet said what sort of thing it is. They are real tasks from this
  /// moment - findable, editable, plannable - rather than sitting in a holding
  /// pen that has to be promoted out of. Holding pens are where captured
  /// things go to die.
  Future<void> _drainCaptures() async {
    final widget = _homeWidget;
    if (widget == null) return;

    for (final title in await widget.drainCaptures()) {
      final task = await _tasks.createTask(
        kind: TaskKind.oneoff,
        title: title,
        now: now,
        needsSorting: true,
      );
      _justCaptured.add(task.id);
    }
  }

  /// Puts every recurring task that is due today on today's plan.
  ///
  /// Habits and daily-repeating tasks used to be *offered*: they appeared in a
  /// suggestion strip and had to be accepted, every single day. That is a tap
  /// per habit per day to say yes to something already decided, and a day the
  /// user never opened before evening looked empty when it was not.
  ///
  /// Now the day builds itself and the plan is edited instead. Removing a row
  /// is still possible and still means "not today"; what is gone is having to
  /// ask for the same thing every morning.
  ///
  /// Idempotent through [TodayPlanner.addToDay], which skips a task already on
  /// the day - so a removed row does *not* come back on the next load, because
  /// removal deletes the entry and this only adds what is missing. That is the
  /// one rough edge: a habit dismissed for today reappears if the app is
  /// reloaded. Accepted deliberately over the alternative, which is a second
  /// per-day table recording refusals.
  Future<void> _planRecurring() async {
    final weekday = TodayPlanner.weekdayOf(dayKey);
    final due = [
      for (final task in tasks)
        if (task.isDueOn(weekday)) task.id,
    ];
    if (due.isEmpty) return;

    final before = plan.length;
    plan = const TodayPlanner().addToDay(
      dayKey: dayKey,
      plan: plan,
      taskIds: due,
      source: PlanSource.habit,
    );
    // Only written when something was actually added: this runs on every load,
    // and a save per load is a write per app open for no change.
    if (plan.length != before) await _savePlan();
  }

  /// Ids drained from the widget and not yet put on today's plan.
  ///
  /// Held between the two steps because [_drainCaptures] runs before [plan] is
  /// read from the database - planning inside the drain would write to a list
  /// that the next line then overwrites.
  final List<String> _justCaptured = [];

  /// Puts anything just captured on today's plan.
  ///
  /// The inbox alone made the widget look broken: a line was typed on the home
  /// screen, the app was opened, and today's list was unchanged. Sorting is
  /// still deferred - the task keeps [Task.needsSorting] and still shows in the
  /// inbox - but something written down today belongs on today's list, because
  /// wanting to do it now is what made it worth interrupting for.
  Future<void> _planCaptured() async {
    if (_justCaptured.isEmpty) return;
    final ids = [..._justCaptured];
    _justCaptured.clear();
    await addToToday(ids);
  }

  /// The last [days] days of per-app spend, for checking against the phone's
  /// own counter.
  ///
  /// Reads `day_spend`, which is the same derived table the Statement's
  /// breakdown uses. Deliberately not a fresh query against
  /// `UsageStatsManager`: the point of the check is to test **what lockIn
  /// stored**, and re-reading the source would compare the phone against
  /// itself and pass no matter what.
  Future<List<AccuracyDay>> accuracyDays({int days = 7}) async {
    final reports = await AccuracyReports.load();
    final watched = await db.select(db.watchedApps).get();
    final labels = {for (final app in watched) app.packageName: app.label};

    final result = <AccuracyDay>[];
    for (var back = 0; back < days; back++) {
      final key = addDays(dayKey, -back);
      final rows = await (db.select(db.daySpend)
            ..where((t) => t.dayKey.equals(key))
            ..where((t) => t.deletedAt.isNull()))
          .get();

      final apps = [
        for (final row in rows)
          AccuracyApp(
            packageName: row.packageName,
            label: labels[row.packageName] ?? row.packageName,
            seconds: row.seconds,
            reportedMinutes: reports['$key.${row.packageName}'],
          ),
      ]..sort((a, b) => b.seconds.compareTo(a.seconds));

      result.add(
        AccuracyDay(
          dayKey: key,
          label: back == 0
              ? 'Today'
              : back == 1
                  ? 'Yesterday'
                  : _formatDate(_ledger.engine.dayStart(key)),
          apps: apps,
        ),
      );
    }
    return result;
  }

  Future<void> recordAccuracy(
    String dayKey,
    String packageName,
    int? minutes,
  ) =>
      AccuracyReports.save(dayKey, packageName, minutes);

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
