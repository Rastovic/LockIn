import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tally_engine/tally_engine.dart';

import '../format/durations.dart';
import '../theme/tally_theme_data.dart';
import '../widgets/sticker_chip.dart';
import '../widgets/task_row.dart';

/// Everything Manage Tasks needs to draw.
final class ManageTasksModel {
  const ManageTasksModel({
    required this.tasks,
    required this.now,
    this.projects = const [],
    this.streaks = const {},
    this.plannedToday = const {},
  });

  final List<Task> tasks;
  final DateTime now;

  /// The folders project tasks are filed under.
  final List<Project> projects;

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
    this.inbox = false,
    this.onCreate,
    this.onEdit,
    this.onDelete,
    this.onAddToToday,
    this.onStartFocus,
    this.onInbox,
    this.onCreateProject,
    this.onAddToProject,
    this.onRenameProject,
    this.onDeleteProject,
    super.key,
  });

  final ManageTasksModel model;

  /// The kind being shown, or null for All.
  final TaskKind? segment;

  /// True when the Inbox segment is showing, which is not a kind.
  ///
  /// Kept as a separate flag rather than a fifth enum value because "captured
  /// and not yet sorted" is a state a task passes through, not a sort of thing
  /// it is. A task in the inbox is already a one-off; it just has not been
  /// looked at.
  final bool inbox;

  final ValueChanged<TaskKind?> onSegment;

  final VoidCallback? onCreate;
  final void Function(Task task)? onEdit;

  /// Holding a row. The screen only reports it; the caller confirms, so a
  /// long press that was meant as a scroll cannot lose a task on its own.
  final void Function(Task task)? onDelete;
  final void Function(Task task)? onAddToToday;
  final void Function(Task task)? onStartFocus;

  /// Shows the Inbox segment.
  final VoidCallback? onInbox;

  final VoidCallback? onCreateProject;
  final void Function(Project project)? onAddToProject;
  final void Function(Project project)? onRenameProject;
  final void Function(Project project)? onDeleteProject;

  static const _labels = {
    TaskKind.habit: 'Daily',
    TaskKind.quick: 'Quick',
    TaskKind.projectTask: 'Projects',
    TaskKind.dread: 'Avoiding',
    TaskKind.oneoff: 'Someday',
  };

  static const _planner = TodayPlanner();

  List<Task> get _visible => inbox
      ? [
          for (final task in model.tasks)
            if (!task.isArchived && task.needsSorting) task,
        ]
      : [
          for (final task in model.tasks)
            if (!task.isArchived && (segment == null || task.kind == segment))
              task,
        ];

  int get _inboxCount =>
      model.tasks.where((t) => !t.isArchived && t.needsSorting).length;

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
              inbox: inbox,
              inboxCount: _inboxCount,
              onChanged: onSegment,
              onInbox: onInbox,
            ),
            Expanded(
              child: inbox
                  ? (visible.isEmpty
                      ? const _EmptyInbox()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: visible.length,
                          itemBuilder: (context, index) =>
                              _row(context, visible[index]),
                        ))
                  : segment == TaskKind.projectTask
                  ? _ProjectList(
                      projects: model.projects
                          .where((p) => !p.isArchived)
                          .toList(),
                      tasksFor: (id) => [
                        for (final task in model.tasks)
                          if (!task.isArchived &&
                              task.kind == TaskKind.projectTask &&
                              task.projectId == id)
                            task,
                      ],
                      unfiled: [
                        for (final task in model.tasks)
                          if (!task.isArchived &&
                              task.kind == TaskKind.projectTask &&
                              task.projectId == null)
                            task,
                      ],
                      buildRow: _row,
                      onAddToProject: onAddToProject,
                      onRenameProject: onRenameProject,
                      onDeleteProject: onDeleteProject,
                    )
                  : visible.isEmpty
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
            _CreateButton(
              label: inbox
                  ? 'New task'
                  : segment == TaskKind.projectTask
                      ? 'New project'
                      : _createLabel,
              onTap: !inbox && segment == TaskKind.projectTask
                  ? onCreateProject
                  : onCreate,
            ),
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
          onLongPress: onDelete == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onDelete!(task);
                },
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
        TaskKind.quick => 'New quick task',
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

      case TaskKind.quick:
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
    required this.inbox,
    required this.inboxCount,
    required this.onChanged,
    required this.onInbox,
  });

  final TaskKind? selected;
  final Map<TaskKind, String> labels;
  final Map<TaskKind, int> counts;
  final int allCount;
  final bool inbox;
  final int inboxCount;
  final ValueChanged<TaskKind?> onChanged;
  final VoidCallback? onInbox;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // First, and only while there is something in it. A permanently
          // visible empty inbox is a chore on display.
          if (inboxCount > 0) ...[
            Semantics(
              button: true,
              selected: inbox,
              label: 'Inbox',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onInbox,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: inbox ? tokens.states.low : tokens.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Inbox $inboxCount',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: inbox ? tokens.bg : tokens.states.low,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          for (final entry in <MapEntry<TaskKind?, String>>[
            const MapEntry(null, 'All'),
            ...labels.entries,
          ]) ...[
            Semantics(
              button: true,
              selected: !inbox && selected == entry.key,
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
                    color: !inbox && selected == entry.key
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
                          color: !inbox && selected == entry.key
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
    TaskKind.quick: (
      'Nothing quick yet',
      'A minute or less. Supplements, the bins, water the plants. No streak '
          'and no timer, because two seconds is not something to fail at.',
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

/// Projects, each opening to the tasks filed under it.
///
/// **A project has no time of its own.** The header shows the sum of its
/// tasks' estimates, derived on the spot rather than stored, because a stored
/// total is a second number that starts disagreeing with its own parts the
/// first time a task changes. It is a folder with a name, and what is inside
/// are ordinary project tasks.
class _ProjectList extends StatefulWidget {
  const _ProjectList({
    required this.projects,
    required this.tasksFor,
    required this.unfiled,
    required this.buildRow,
    this.onAddToProject,
    this.onRenameProject,
    this.onDeleteProject,
  });

  final List<Project> projects;
  final List<Task> Function(String projectId) tasksFor;

  /// Project tasks with no project, including anything left behind when a
  /// project was deleted. Never hidden: an unfiled task is still work.
  final List<Task> unfiled;

  final Widget Function(BuildContext, Task) buildRow;
  final void Function(Project project)? onAddToProject;
  final void Function(Project project)? onRenameProject;
  final void Function(Project project)? onDeleteProject;

  @override
  State<_ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<_ProjectList> {
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    if (widget.projects.isEmpty && widget.unfiled.isEmpty) {
      return const _EmptySegment(kind: TaskKind.projectTask);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        for (final project in widget.projects) ...[
          _ProjectHeader(
            project: project,
            tasks: widget.tasksFor(project.id),
            open: _open.contains(project.id),
            onToggle: () => setState(
              () => _open.contains(project.id)
                  ? _open.remove(project.id)
                  : _open.add(project.id),
            ),
            onAdd: widget.onAddToProject == null
                ? null
                : () => widget.onAddToProject!(project),
            onRename: widget.onRenameProject == null
                ? null
                : () => widget.onRenameProject!(project),
            onDelete: widget.onDeleteProject == null
                ? null
                : () => widget.onDeleteProject!(project),
          ),
          if (_open.contains(project.id)) ...[
            for (final task in widget.tasksFor(project.id))
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: widget.buildRow(context, task),
              ),
            if (widget.tasksFor(project.id).isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 12, 10),
                child: Text('Nothing in here yet.', style: text.labelMedium),
              ),
          ],
          const SizedBox(height: 6),
        ],
        if (widget.unfiled.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Text(
              'NOT IN A PROJECT  ${widget.unfiled.length}',
              style: text.labelSmall?.copyWith(color: tokens.inkFaint),
            ),
          ),
          for (final task in widget.unfiled) widget.buildRow(context, task),
        ],
      ],
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.project,
    required this.tasks,
    required this.open,
    required this.onToggle,
    this.onAdd,
    this.onRename,
    this.onDelete,
  });

  final Project project;
  final List<Task> tasks;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback? onAdd;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    // Derived, never stored. Tasks without an estimate simply contribute
    // nothing rather than being guessed at.
    final estimated = tasks.fold(0, (sum, t) => sum + (t.estimateMinutes ?? 0));
    final left = tasks.length;

    return Semantics(
      button: true,
      expanded: open,
      label: '${project.name}, $left tasks',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (project.stickerId != null) ...[
                StickerChip(stickerId: project.stickerId!, size: 26),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: text.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      // The project's own line never claims a duration of its
                      // own: it reports what its tasks add up to, and says so.
                      left == 0
                          ? 'empty'
                          : estimated == 0
                              ? '$left tasks'
                              : '$left tasks · ${formatDuration(estimated * 60)} planned',
                      style: text.labelMedium,
                    ),
                  ],
                ),
              ),
              if (onAdd != null)
                Semantics(
                  button: true,
                  label: 'Add a task to ${project.name}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onAdd,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.add, size: 20, color: tokens.inkMuted),
                    ),
                  ),
                ),
              if (onRename != null)
                Semantics(
                  button: true,
                  label: 'Rename ${project.name}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onRename,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: tokens.inkFaint,
                      ),
                    ),
                  ),
                ),
              Icon(
                open ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: tokens.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The inbox, once it is empty.
///
/// Says the work is finished rather than that the feature is unused. An empty
/// inbox is the good state, and the copy should not read like something is
/// missing from it.
class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing to sort',
              style: text.titleLarge?.copyWith(color: tokens.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Anything you jot down from the home screen lands here until '
              'you decide what it is.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
