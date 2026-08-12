import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/task_row.dart';

/// Everything Manage Tasks needs to draw.
final class ManageTasksModel {
  const ManageTasksModel({
    required this.tasks,
    required this.now,
    this.streaks = const {},
    this.plannedToday = const {},
  });

  final List<Task> tasks;
  final DateTime now;

  /// Current streak per habit id.
  final Map<String, int> streaks;

  /// Task ids already in today's plan, so a row can say so rather than letting
  /// the user add the same thing twice.
  final Set<String> plannedToday;
}

/// Manage Tasks.
///
/// **Four kinds, because these are genuinely different objects.** A habit
/// carries a streak, a project task stacks sessions, a dread task counts the
/// days it has been avoided, and a one-off carries nothing at all. Flattening
/// them into one undifferentiated list is what makes task apps confusing, so
/// the split is the screen's structure.
///
/// There is also an **All** segment, added after a day of real use: knowing
/// which of four buckets something was filed under is a poor way to find it
/// again, and checking four tabs to answer "what do I actually have" is worse.
/// All keeps the kinds visible as **headed groups** rather than dissolving
/// them, so it answers the "everything at once" question without giving up the
/// distinction the rest of the screen is built on.
class ManageTasksScreen extends StatelessWidget {
  const ManageTasksScreen({
    required this.model,
    required this.segment,
    required this.onSegment,
    this.onCreate,
    this.onEdit,
    this.onAddToToday,
    this.onStartFocus,
    super.key,
  });

  final ManageTasksModel model;

  /// The kind being shown, or null for All.
  final TaskKind? segment;

  final ValueChanged<TaskKind?> onSegment;

  final VoidCallback? onCreate;
  final void Function(Task task)? onEdit;
  final void Function(Task task)? onAddToToday;
  final void Function(Task task)? onStartFocus;

  static const _labels = {
    TaskKind.habit: 'Daily',
    TaskKind.projectTask: 'Projects',
    TaskKind.dread: 'Avoiding',
    TaskKind.oneoff: 'Someday',
  };

  static const _planner = TodayPlanner();

  List<Task> get _visible => [
        for (final task in model.tasks)
          if (!task.isArchived && (segment == null || task.kind == segment))
            task,
      ];

  /// The All view, in kind order, with empty kinds left out.
  List<(TaskKind, List<Task>)> get _grouped => [
        for (final kind in TaskKind.values)
          if (model.tasks.any((t) => t.kind == kind && !t.isArchived))
            (
              kind,
              [
                for (final task in model.tasks)
                  if (task.kind == kind && !task.isArchived) task,
              ],
            ),
      ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final visible = _visible;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Text('Tasks', style: text.headlineMedium),
                  const Spacer(),
                  Text('${visible.length} here', style: text.labelMedium),
                ],
              ),
            ),
            _Segments(
              selected: segment,
              labels: _labels,
              counts: {
                for (final kind in TaskKind.values)
                  kind: model.tasks
                      .where((t) => t.kind == kind && !t.isArchived)
                      .length,
              },
              allCount: model.tasks.where((t) => !t.isArchived).length,
              onChanged: onSegment,
            ),
            Expanded(
              child: visible.isEmpty
                  ? _EmptySegment(kind: segment)
                  : segment == null
                      ? _AllList(
                          groups: _grouped,
                          labels: _labels,
                          buildRow: _row,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: visible.length,
                          itemBuilder: (context, index) =>
                              _row(context, visible[index]),
                        ),
            ),
            _CreateButton(label: _createLabel, onTap: onCreate),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Task task) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => onEdit?.call(task),
          behavior: HitTestBehavior.opaque,
          child: TaskRow(
            title: task.title,
            done: false,
            showGrip: false,
            stickerId: task.stickerId,
            estimateMinutes: task.estimateMinutes,
            subtitle: _subtitleFor(task),
            onToggle: model.plannedToday.contains(task.id)
                ? null
                : () => onAddToToday?.call(task),
            onStartFocus: () => onStartFocus?.call(task),
          ),
        ),
      );

  String get _createLabel => switch (segment) {
        TaskKind.habit => 'New daily task',
        TaskKind.projectTask => 'New project task',
        TaskKind.dread => 'Add something you are avoiding',
        TaskKind.oneoff => 'New task',
        null => 'New task',
      };

  /// The one line each kind earns, and nothing more.
  String? _subtitleFor(Task task) {
    switch (task.kind) {
      case TaskKind.habit:
        final streak = model.streaks[task.id] ?? 0;
        final days = task.habitWeekdays.isEmpty
            ? 'every day'
            : _weekdayList(task.habitWeekdays);
        return streak > 0 ? '$days · streak $streak' : days;

      case TaskKind.dread:
        final avoided = _planner.avoidedDaysFor(task, now: model.now);
        return avoided > 0 ? 'avoided $avoided days' : 'added today';

      case TaskKind.projectTask:
      case TaskKind.oneoff:
        return model.plannedToday.contains(task.id) ? 'in today' : null;
    }
  }

  static String _weekdayList(Set<int> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => names[d - 1]).join(' · ');
  }
}

/// The All view: every kind, still in its own headed group.
class _AllList extends StatelessWidget {
  const _AllList({
    required this.groups,
    required this.labels,
    required this.buildRow,
  });

  final List<(TaskKind, List<Task>)> groups;
  final Map<TaskKind, String> labels;
  final Widget Function(BuildContext, Task) buildRow;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        for (final (kind, tasks) in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Text(
              '${labels[kind]!.toUpperCase()}  ${tasks.length}',
              style: text.labelSmall,
            ),
          ),
          for (final task in tasks) buildRow(context, task),
        ],
      ],
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({
    required this.selected,
    required this.labels,
    required this.counts,
    required this.allCount,
    required this.onChanged,
  });

  final TaskKind? selected;
  final Map<TaskKind, String> labels;
  final Map<TaskKind, int> counts;
  final int allCount;
  final ValueChanged<TaskKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final entry in <MapEntry<TaskKind?, String>>[
            const MapEntry(null, 'All'),
            ...labels.entries,
          ]) ...[
            Semantics(
              button: true,
              selected: selected == entry.key,
              label: entry.value,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == entry.key
                        ? tokens.states.solvent
                        : tokens.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    // The count sits in the chip so the shape of the whole
                    // task list is readable without opening each segment.
                    '${entry.value} '
                        '${entry.key == null ? allCount : counts[entry.key] ?? 0}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: selected == entry.key
                              ? tokens.bg
                              : tokens.inkMuted,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// The empty state per segment.
///
/// Each says what the segment is *for*, because an empty list is the only place
/// the difference between the four kinds can be explained without a tutorial.
class _EmptySegment extends StatelessWidget {
  const _EmptySegment({required this.kind});

  /// Null is the All segment, which is only empty when nothing exists at all.
  final TaskKind? kind;

  static const _copy = {
    TaskKind.habit: (
      'Nothing daily yet',
      'Things you want to do on a rhythm. These carry a streak.',
    ),
    TaskKind.projectTask: (
      'No project tasks',
      'Pieces of something bigger. Sessions stack up, and there are no '
          'deadlines.',
    ),
    TaskKind.dread: (
      'Nothing here',
      'The things you keep putting off. This list counts the days, which is '
          'the only pressure it applies.',
    ),
    TaskKind.oneoff: (
      'Nothing in the list',
      'One-off things, kept until you plan them into a day. They carry '
          'nothing, and that is the point.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final (title, detail) = kind == null
        ? (
            'No tasks yet',
            'Anything you add shows up here, whichever kind it is.',
          )
        : _copy[kind]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: text.titleLarge?.copyWith(color: tokens.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(detail, style: text.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.states.solvent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.bg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
