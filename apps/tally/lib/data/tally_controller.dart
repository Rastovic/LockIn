import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';
import 'package:vitals_core/vitals_core.dart';

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
    DateTime Function()? clock,
  })  : _clock = clock ?? (() => DateTime.now().toUtc()),
        _tasks = TaskRepository(db, installId: installId),
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
  final LedgerRepository _ledger;
  final UsageSource? _usage;

  List<Task> tasks = const [];
  List<AppSpend> spendByApp = const [];
  List<WatchableApp> watchable = const [];
  UsageAccess usageAccess = UsageAccess.denied;
  List<PlanEntry> plan = const [];
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
    final day = ledger?.days.isNotEmpty ?? false ? ledger!.days.last : null;
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
    usageAccess = await _usage?.access() ?? UsageAccess.unavailable;
    tasks = await _tasks.tasks();
    plan = await _tasks.planFor(dayKey);
    streaks = await _tasks.habitStreaks(dayKey: dayKey);
    await _reconcile();
    await loadWatchable();
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
      await _storeSpend(spans);
    }

    ledger = await _ledger.recomputeAndStore(
      fromDay: addDays(dayKey, -30),
      toDay: dayKey,
      now: now,
    );
    spendByApp = await _loadSpendByApp();
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

    final spend = [
      for (final row in rows)
        AppSpend(
          packageName: row.packageName,
          label: labels[row.packageName]?.label ?? row.packageName,
          seconds: row.seconds,
          notInstalled: labels[row.packageName]?.notInstalled ?? false,
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

  /// Replaces today's stored spans with what the platform just reported.
  ///
  /// Replaced rather than appended: the source returns the full window every
  /// time, so appending would double-count on every single reconcile.
  Future<void> _storeSpend(List<UsageSpan> spans) async {
    final stamp = now.millisecondsSinceEpoch;
    final offset = now.timeZoneOffset.inMinutes;

    await db.transaction(() async {
      await (db.delete(db.spendSpans)..where((t) => t.dayKey.equals(dayKey)))
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

  Future<void> createTask(TaskDraft draft) async {
    await _tasks.createTask(
      kind: draft.kind,
      title: draft.title,
      now: now,
      stickerId: draft.stickerId,
      estimateMinutes: draft.estimateMinutes,
      habitWeekdays: draft.habitWeekdays,
    );
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

  // --- focus ---------------------------------------------------------------

  void startFocus({String? taskId, int minutes = 25}) {
    focus = FocusRun(
      id: Ids.newId(),
      startedAt: now,
      planned: Duration(minutes: minutes),
      taskId: taskId,
    );
    notifyListeners();
  }

  void pauseFocus() {
    focus = focus?.pause(now);
    notifyListeners();
  }

  void resumeFocus() {
    focus = focus?.resume(now);
    notifyListeners();
  }

  void extendFocus(Duration by) {
    focus = focus?.extend(by);
    notifyListeners();
  }

  /// Ends the block and banks whatever was worked.
  ///
  /// Giving up and finishing are the same path: both produce a session of the
  /// length actually focused, and the engine applies its usual rules. A block
  /// under the earning floor simply earns nothing, with nothing said about it.
  Future<void> endFocus() async {
    final run = focus?.finish(now);
    focus = null;
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

  // --- helpers -------------------------------------------------------------

  LibraryItem? _suggestion() => const SuggestionPicker().suggestionFor(
        dayKey: dayKey,
        installId: installId,
        library: shippedLibrary,
        addedItemIds: {for (final task in tasks) task.id},
      );

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
