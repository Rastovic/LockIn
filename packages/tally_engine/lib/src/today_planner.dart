import 'package:vitals_core/vitals_core.dart';

import 'task.dart';

/// One row as the Today screen draws it.
final class TodayRow {
  const TodayRow({
    required this.entry,
    required this.task,
    required this.avoidedDays,
  });

  final PlanEntry entry;
  final Task task;

  /// For a dread task, how long it had been avoided when it was planned.
  /// Zero for every other kind.
  final int avoidedDays;

  bool get isDone => entry.isDone;
  String? get stickerId => task.stickerId;
  int get estimateSeconds => task.estimateSeconds;
}

/// Everything the Today screen needs, and nothing that could earn a minute.
///
/// **There is deliberately no credit, balance or minutes-earned field on this
/// type.** The day layer cannot pay the ledger because it has no vocabulary for
/// it. That is enforcement by type, not by discipline.
final class TodayView {
  const TodayView({
    required this.dayKey,
    required this.rows,
    required this.offeredHabits,
    required this.plannedSeconds,
  });

  final String dayKey;

  /// The plan, in the user's order.
  final List<TodayRow> rows;

  /// Recurring things due today that are not already planned: habits due on
  /// this weekday, and every quick task.
  ///
  /// **Offered, never auto-added.** An app that fills your day for you is an
  /// app you stop trusting by Thursday. That holds for a two second job as
  /// much as for a habit - the difference between a list you keep and a list
  /// you resent is who put the items on it.
  final List<Task> offeredHabits;

  /// Total estimate of everything planned, done or not.
  ///
  /// This is the only feedback on overloading a day. Eight tasks reads as
  /// "6h 20m planned" and self-corrects. **No cap, no warning, no colour
  /// change** - the number is the warning, and that is this app's whole tone.
  final int plannedSeconds;

  int get plannedMinutes => (plannedSeconds / 60).round();

  int get doneCount => rows.where((r) => r.isDone).length;

  bool get isEmpty => rows.isEmpty;

  /// True when there was something to do and it is all done.
  bool get allDone => rows.isNotEmpty && doneCount == rows.length;
}

/// The day layer: what is planned, what is offered, what carries over.
///
/// Pure Dart, alongside [LedgerEngine] and sharing nothing with it. The two
/// engines never call each other, which is the structural reason a checkbox
/// cannot move the balance.
final class TodayPlanner {
  const TodayPlanner();

  /// Assembles [dayKey]'s view.
  ///
  /// Tolerates a plan entry whose task has been deleted or archived: the row is
  /// dropped rather than throwing. Deleting a task while it sits in today's
  /// plan is an ordinary thing a user does, not an error.
  TodayView buildToday({
    required String dayKey,
    required List<Task> tasks,
    required List<PlanEntry> plan,
    required DateTime now,
  }) {
    final byId = {for (final task in tasks) task.id: task};

    final rows = <TodayRow>[];
    for (final entry in plan.where((e) => e.dayKey == dayKey)) {
      final task = byId[entry.taskId];
      if (task == null || task.isArchived) continue;
      rows.add(
        TodayRow(
          entry: entry,
          task: task,
          avoidedDays: avoidedDaysFor(task, now: now),
        ),
      );
    }
    rows.sort((a, b) => a.entry.sortOrder.compareTo(b.entry.sortOrder));

    final plannedIds = {for (final row in rows) row.task.id};
    final weekday = _weekdayOf(dayKey);
    final offered = tasks
        .where((t) => t.isDueOn(weekday) && !plannedIds.contains(t.id))
        .toList();

    return TodayView(
      dayKey: dayKey,
      rows: rows,
      offeredHabits: offered,
      plannedSeconds: rows.fold(0, (sum, row) => sum + row.estimateSeconds),
    );
  }

  /// How long a dread task has gone unfinished. Zero for other kinds.
  int avoidedDaysFor(Task task, {required DateTime now}) {
    if (task.kind != TaskKind.dread) return 0;
    final since = task.lastCompletedAt ?? task.createdAt;
    final days = now.difference(since).inDays;
    return days < 0 ? 0 : days;
  }

  /// Adds tasks to a day, appending them after whatever is already there.
  List<PlanEntry> addToDay({
    required String dayKey,
    required List<PlanEntry> plan,
    required List<String> taskIds,
    PlanSource source = PlanSource.manual,
  }) {
    final today = plan.where((e) => e.dayKey == dayKey).toList();
    final present = {for (final e in today) e.taskId};
    var next = today.isEmpty
        ? 0
        : today.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    final added = <PlanEntry>[];
    for (final taskId in taskIds) {
      // A habit offered and accepted twice must still appear once.
      if (present.contains(taskId)) continue;
      present.add(taskId);
      added.add(
        PlanEntry(
          id: Ids.newId(),
          dayKey: dayKey,
          taskId: taskId,
          sortOrder: next++,
          source: source,
        ),
      );
    }
    return [...plan, ...added];
  }

  /// Moves the row at [fromIndex] to [toIndex] and renumbers the day.
  ///
  /// Renumbering from zero every time keeps `sortOrder` dense, so an order
  /// survives a rebuild instead of drifting into ties.
  List<PlanEntry> reorder({
    required String dayKey,
    required List<PlanEntry> plan,
    required int fromIndex,
    required int toIndex,
  }) {
    final today = plan.where((e) => e.dayKey == dayKey).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (fromIndex < 0 ||
        fromIndex >= today.length ||
        toIndex < 0 ||
        toIndex >= today.length) {
      throw RangeError('Cannot move $fromIndex to $toIndex in ${today.length}');
    }
    final moved = today.removeAt(fromIndex);
    today.insert(toIndex, moved);

    final renumbered = <String, PlanEntry>{
      for (var i = 0; i < today.length; i++)
        today[i].id: today[i].copyWith(sortOrder: i),
    };
    return [
      for (final entry in plan) renumbered[entry.id] ?? entry,
    ];
  }

  /// Ticks a row.
  ///
  /// Returns the updated plan and the sticker stamp it earned, if the task
  /// carries a sticker. **It cannot return minutes**, because the return type
  /// has nowhere to put them.
  ({List<PlanEntry> plan, StickerStamp? stamp}) complete({
    required List<PlanEntry> plan,
    required String entryId,
    required List<Task> tasks,
    required DateTime at,
    required String dayKey,
  }) {
    final index = plan.indexWhere((e) => e.id == entryId);
    if (index < 0) return (plan: plan, stamp: null);
    final entry = plan[index];
    // Completing an already-done row must not stamp twice.
    if (entry.isDone) return (plan: plan, stamp: null);

    final updated = [...plan]..[index] = entry.copyWith(doneAt: at);

    final task = tasks.where((t) => t.id == entry.taskId).firstOrNull;
    final stickerId = task?.stickerId;
    if (stickerId == null) return (plan: updated, stamp: null);

    return (
      plan: updated,
      stamp: StickerStamp(
        id: Ids.newId(),
        dayKey: dayKey,
        stickerId: stickerId,
        taskId: entry.taskId,
        at: at,
      ),
    );
  }

  /// Unticks a row and removes any stamp it produced.
  ///
  /// Mis-taps are guaranteed, so undoing one must cost nothing and leave no
  /// trace on the sticker sheet.
  ({List<PlanEntry> plan, List<StickerStamp> stamps}) uncomplete({
    required List<PlanEntry> plan,
    required List<StickerStamp> stamps,
    required String entryId,
  }) {
    final index = plan.indexWhere((e) => e.id == entryId);
    if (index < 0) return (plan: plan, stamps: stamps);
    final entry = plan[index];
    if (!entry.isDone) return (plan: plan, stamps: stamps);

    final updated = [...plan]..[index] = entry.copyWith(clearDone: true);
    final kept = stamps
        .where((s) => !(s.taskId == entry.taskId && s.dayKey == entry.dayKey))
        .toList();
    return (plan: updated, stamps: kept);
  }

  /// What happens at the day boundary.
  ///
  /// **Undone rows are dropped from the plan and stay in the pool.** They are
  /// not rolled forward and never stacked into a wall of yesterday's failures.
  /// A dread task's avoided-days counter ticks up on its own, which is the
  /// honest record, and that is the only consequence.
  ///
  /// This is the single most important tone decision in the day layer. Every
  /// planner that auto-carries becomes a guilt archive, and guilt archives get
  /// uninstalled.
  ({List<PlanEntry> plan, List<String> droppedTaskIds}) closeDay({
    required String dayKey,
    required List<PlanEntry> plan,
  }) {
    final dropped = <String>[];
    final kept = <PlanEntry>[];
    for (final entry in plan) {
      if (entry.dayKey == dayKey && !entry.isDone) {
        dropped.add(entry.taskId);
        continue;
      }
      kept.add(entry);
    }
    return (plan: kept, droppedTaskIds: dropped);
  }

  /// Everything unscheduled: the pool the `+ from my list` sheet shows.
  List<Task> pool({
    required List<Task> tasks,
    required List<PlanEntry> plan,
    required String dayKey,
  }) {
    final planned = {
      for (final e in plan.where((e) => e.dayKey == dayKey)) e.taskId,
    };
    return tasks
        .where((t) => !t.isArchived && !planned.contains(t.id))
        .toList();
  }

  static int _weekdayOf(String dayKey) {
    final date = parseDayKey(dayKey);
    if (date == null) {
      throw ArgumentError.value(dayKey, 'dayKey', 'Not a YYYY-MM-DD day key');
    }
    return date.weekday;
  }
}
