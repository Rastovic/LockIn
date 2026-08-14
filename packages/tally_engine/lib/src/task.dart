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

  /// A minute or less: supplements, water the plants, put the bins out.
  ///
  /// **Deliberately not a habit.** A habit carries a streak, and a streak on
  /// something this small turns a two second job into something you can fail
  /// at. These carry no streak, no schedule and no estimate - they exist to be
  /// ticked and forgotten, and the only thing they earn is a sticker.
  quick,
}

/// Whether a task comes back tomorrow.
///
/// Stored as a **string**, never an ordinal, so reordering this enum cannot
/// silently reinterpret a year of history.
enum TaskRepeat {
  /// Ticked once and done. It leaves the list.
  once,

  /// Offered again every day, for as long as it exists.
  ///
  /// **Carries no streak.** A streak is a habit's idea, and putting one on
  /// taking supplements turns a two second job into something you can fail at.
  daily,
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
    this.repeat = TaskRepeat.once,
    this.needsSorting = false,
    this.note,
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

  /// Whether this comes back tomorrow.
  ///
  /// A property of the task rather than of its kind. The first version tied it
  /// to [TaskKind.quick] and made every quick task daily, which is wrong twice
  /// over: a one-off quick job has nowhere to go, and a recurring one of any
  /// other kind is impossible to express. What repeats is not something the
  /// app can infer from what sort of thing it is.
  final TaskRepeat repeat;

  /// Captured on the fly, not yet sorted into a kind.
  ///
  /// **It is a real task the moment it is captured**, with a real id and a
  /// row of its own. This says only that nobody has decided what sort of thing
  /// it is, which is why it is a flag rather than a separate kind: a holding
  /// pen you have to promote things out of is a second task list, and things
  /// die in it.
  final bool needsSorting;

  /// The longer version, when the title is not enough on its own.
  ///
  /// Nothing in the ledger reads it. It is there to hold what the task
  /// involves or why it has been sitting untouched, and deliberately has no
  /// effect on anything: notes that start driving behaviour become a second,
  /// worse task system inside the first one.
  final String? note;

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

  /// True when this comes back every day of its own accord.
  ///
  /// Recurs without carrying a schedule or a streak, which is what separates
  /// it from a habit: no weekdays to be due on and nothing to break.
  ///
  /// Kept apart from [isHabitDueOn] rather than folded into it, because "due
  /// on a weekday" is a habit's idea. Sharing the predicate would mean giving
  /// every repeating task a schedule field to ignore.
  bool get recursDaily => repeat == TaskRepeat.daily && !isArchived;

  /// True when this should be offered for [weekday] and is not already done
  /// for the day.
  bool isDueOn(int weekday) => isHabitDueOn(weekday) || recursDaily;

  Task copyWith({
    String? title,
    TaskKind? kind,
    TaskRepeat? repeat,
    bool? needsSorting,
    String? note,
    bool clearNote = false,
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
        kind: kind ?? this.kind,
        title: title ?? this.title,
        createdAt: createdAt,
        repeat: repeat ?? this.repeat,
        needsSorting: needsSorting ?? this.needsSorting,
        note: clearNote ? null : (note ?? this.note),
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

/// A container for project tasks.
///
/// **A project carries no time of its own.** The minutes live on the tasks
/// inside it, and the project's total is derived from them rather than stored.
/// That is the whole reason it is a separate object: a project with its own
/// estimate would be a second number to keep in step with the sum of its
/// parts, and the two would disagree the first time a task changed.
///
/// It carries no due date and no progress bar either. It is a folder with a
/// name, and the tasks inside it are ordinary tasks that happen to be filed.
final class Project {
  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.stickerId,
    this.archivedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? stickerId;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Project copyWith({
    String? name,
    String? stickerId,
    bool clearSticker = false,
    DateTime? archivedAt,
    bool unarchive = false,
  }) =>
      Project(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        stickerId: clearSticker ? null : (stickerId ?? this.stickerId),
        archivedAt: unarchive ? null : (archivedAt ?? this.archivedAt),
      );

  @override
  String toString() => 'Project($id, "$name")';
}
