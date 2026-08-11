import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

import '../data/tally_controller.dart';
import '../platform/android_usage_source.dart';
import '../preview/usage_spike_screen.dart';

/// The app.
///
/// Four tabs, per the settled navigation: Today, Tasks, Stats, Settings. The
/// balance is not a tab - it is one tap up from the strip on Today, because the
/// day is why you opened the app and the number is what you check while you are
/// there.
///
/// Stats and Settings are placeholders until their screens exist. They are in
/// the bar from the start so the shape of the app does not change under the
/// user later.
class TallyApp extends StatefulWidget {
  const TallyApp({required this.controller, super.key});

  final TallyController controller;

  @override
  State<TallyApp> createState() => _TallyAppState();
}

class _TallyAppState extends State<TallyApp> with WidgetsBindingObserver {
  int _tab = 0;
  TaskKind _segment = TaskKind.habit;

  TallyController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.addListener(_onChanged);
    c.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload on resume. The ledger is derived, so whatever happened while the
    // app was away - including a day rolling over - is worked out from stored
    // rows rather than from anything held in memory.
    if (state == AppLifecycleState.resumed) c.load();
  }

  @override
  Widget build(BuildContext context) {
    if (c.loading) {
      return const Scaffold(body: SizedBox.shrink());
    }

    if (c.focus case final run?) {
      final task = run.taskId == null
          ? null
          : c.tasks.where((t) => t.id == run.taskId).firstOrNull;
      return FocusScreen(
        run: run,
        earnRatio: c.settings.earnRatio,
        taskTitle: task?.title ?? 'Focus',
        stickerId: task?.stickerId,
        onPause: c.pauseFocus,
        onResume: c.resumeFocus,
        onExtend: c.extendFocus,
        onGiveUp: c.endFocus,
        onComplete: c.endFocus,
      );
    }

    return Scaffold(
      body: switch (_tab) {
        0 => _buildToday(),
        1 => _buildTasks(),
        2 => const UsageSpikeScreen(source: AndroidUsageSource()),
        _ => const _SettingsPlaceholder(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildToday() => TodayScreen(
        model: c.today,
        onToggle: c.toggle,
        onReorder: c.reorder,
        onStartFocus: (entry) {
          final task = c.tasks.where((t) => t.id == entry.taskId).firstOrNull;
          c.startFocus(
            taskId: task?.id,
            minutes: task?.estimateMinutes ?? 25,
          );
        },
        onStartSession: () => c.startFocus(),
        onAcceptHabit: (habit) =>
            c.addToToday([habit.id], source: PlanSource.habit),
        onAcceptSuggestion: (item) => _acceptSuggestion(item),
        onDismissSuggestion: (_) {},
        onOpenPool: () => setState(() => _tab = 1),
        onOpenBalance: () {},
      );

  Widget _buildTasks() => ManageTasksScreen(
        model: c.manage,
        segment: _segment,
        onSegment: (kind) => setState(() => _segment = kind),
        onCreate: () => _openSheet(initialKind: _segment),
        onEdit: (task) => _openSheet(existing: task),
        onAddToToday: (task) => c.addToToday([task.id]),
        onStartFocus: (task) => c.startFocus(
          taskId: task.id,
          minutes: task.estimateMinutes ?? 25,
        ),
      );

  /// Accepting a suggestion turns it into a real task and plans it, which is
  /// the single tap the plan calls for.
  Future<void> _acceptSuggestion(LibraryItem item) async {
    await c.createTask(
      TaskDraft(
        kind: TaskKind.oneoff,
        title: item.title,
        stickerId: item.stickerId,
        estimateMinutes: item.minutes,
      ),
    );
    final created = c.tasks.lastWhere((t) => t.title == item.title);
    await c.addToToday([created.id], source: PlanSource.suggestion);
  }

  Future<void> _openSheet({Task? existing, TaskKind? initialKind}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskSheet(
        existing: existing,
        initialKind: initialKind ?? TaskKind.oneoff,
        onSave: (draft) {
          Navigator.of(sheetContext).pop();
          if (existing == null) {
            c.createTask(draft);
          } else {
            c.updateTask(existing, draft);
          }
        },
        onDelete: existing == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                c.deleteTask(existing.id);
              },
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Settings are not built yet. Theme, the numbers that drive the '
            'ledger, notifications and backup all live here.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
