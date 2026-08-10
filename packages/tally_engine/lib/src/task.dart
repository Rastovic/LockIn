/// The four kinds of task, which are genuinely different objects.
///
/// Pretending otherwise is what makes task apps confusing, so the Manage Tasks
/// tab segments them rather than mixing them into one list.
enum TaskKind {
  /// "piano 20 min, 5x/week". Carries a streak.
  habit,

  /// A task inside a project. Sessions stack, no deadlines.
  projectTask,

  /// Something being avoided. Tracks how long it has been avoided.
  dread,

  /// A plain one-off. Lives in the pool until it is planned. Carries nothing,
  /// and that is the point.
  oneoff,
}

/// Anything the user might plan into a day.
///
/// **A task carries no minutes and no credit.** Completing one earns nothing;
/// only a timed focus session earns. The absence of any credit field here is
/// the first line of that defence.
final class Task {
  const Task({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.stickerId,
    this.estimateMinutes,
    this.projectId,
    this.habitWeekdays = const {},
    this.lastCompletedAt,
    this.archivedAt,
  });

  final String id;
  final TaskKind kind;
  final String title;
  final DateTime createdAt;

  /// The category sticker, or null. **Most tasks will have none**, so an
  /// unstickered task must look deliberate rather than broken.
  final String? stickerId;

  /// What the user thinks it will take. Feeds the day's planned-minutes total.
  final int? estimateMinutes;

  final String? projectId;

  /// For [TaskKind.habit]: ISO weekdays (1 = Monday) the habit is due.
  ///
  /// Empty means every day.
  final Set<int> habitWeekdays;

  final DateTime? lastCompletedAt;

  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  int get estimateSeconds => (estimateMinutes ?? 0) * 60;

  /// True when a habit is due on [weekday] (ISO, 1 = Monday).
  bool isHabitDueOn(int weekday) =>
      kind == TaskKind.habit &&
      !isArchived &&
      (habitWeekdays.isEmpty || habitWeekdays.contains(weekday));

  Task copyWith({
    String? title,
    String? stickerId,
    bool clearSticker = false,
    int? estimateMinutes,
    bool clearEstimate = false,
    Set<int>? habitWeekdays,
    DateTime? lastCompletedAt,
    DateTime? archivedAt,
    bool unarchive = false,
  }) =>
      Task(
        id: id,
        kind: kind,
        title: title ?? this.title,
        createdAt: createdAt,
        stickerId: clearSticker ? null : (stickerId ?? this.stickerId),
        estimateMinutes:
            clearEstimate ? null : (estimateMinutes ?? this.estimateMinutes),
        projectId: projectId,
        habitWeekdays: habitWeekdays ?? this.habitWeekdays,
        lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
        archivedAt: unarchive ? null : (archivedAt ?? this.archivedAt),
      );

  @override
  String toString() => 'Task($id, ${kind.name}, "$title")';
}

/// Where a row in today's plan came from.
///
/// Kept because the split of where your day actually came from is one query and
/// is genuinely interesting on the Insights tab.
enum PlanSource {
  /// The user added it by hand, from the pool or inline.
  manual,

  /// A habit that was due and was accepted.
  habit,

  /// The day's library suggestion, accepted.
  suggestion,
}

/// One row of one day's plan.
final class PlanEntry {
  const PlanEntry({
    required this.id,
    required this.dayKey,
    required this.taskId,
    required this.sortOrder,
    required this.source,
    this.doneAt,
  });

  final String id;
  final String dayKey;
  final String taskId;

  /// Explicit, because id order is not an ordering. UUID v7 only sorts across
  /// milliseconds, and two rows added in one tap can share one.
  final int sortOrder;

  final PlanSource source;
  final DateTime? doneAt;

  bool get isDone => doneAt != null;

  PlanEntry copyWith({int? sortOrder, DateTime? doneAt, bool clearDone = false}) =>
      PlanEntry(
        id: id,
        dayKey: dayKey,
        taskId: taskId,
        sortOrder: sortOrder ?? this.sortOrder,
        source: source,
        doneAt: clearDone ? null : (doneAt ?? this.doneAt),
      );

  @override
  String toString() => 'PlanEntry($dayKey, $taskId, #$sortOrder'
      '${isDone ? ', done' : ''})';
}

/// A completed task's category sticker, stamped onto the month's sheet.
///
/// **The second currency.** Completion pays one of these and never a minute,
/// which is what makes a checkbox unfarmable while still being worth ticking.
final class StickerStamp {
  const StickerStamp({
    required this.id,
    required this.dayKey,
    required this.stickerId,
    required this.taskId,
    required this.at,
  });

  final String id;
  final String dayKey;
  final String stickerId;
  final String taskId;
  final DateTime at;

  @override
  String toString() => 'StickerStamp($dayKey, $stickerId)';
}
