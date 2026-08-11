import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

import '../data/tally_controller.dart';
import '../platform/android_usage_source.dart';

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
  bool _showBalance = false;

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

    if (_showBalance) {
      return BalanceScreen(
        model: c.balanceModel,
        onClose: () => setState(() => _showBalance = false),
      );
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
        2 => _buildStats(),
        _ => _buildSettings(),
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
        onOpenPool: _openPool,
        onOpenBalance: () => setState(() => _showBalance = true),
      );

  /// The pool: everything created and not yet planned.
  Future<void> _openPool() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PoolSheet(
        available: c.pool,
        now: c.now,
        onAdd: (ids) {
          Navigator.of(sheetContext).pop();
          c.addToToday(ids);
        },
      ),
    );
  }

  StatementPeriod _period = StatementPeriod.week;

  Widget _buildStats() => FutureBuilder<StatementModel>(
        // Rebuilt on every period change and every controller notification,
        // so a session finished on Today is reflected here without a manual
        // refresh.
        key: ValueKey('${_period.name}-${c.plan.length}-${c.tasks.length}'),
        future: c.statement(_period),
        builder: (context, snapshot) {
          final model = snapshot.data;
          if (model == null) {
            return Scaffold(backgroundColor: context.tokens.bg, body: const SizedBox());
          }
          return StatementScreen(
            model: model,
            onPeriod: (period) => setState(() => _period = period),
          );
        },
      );

  Widget _buildSettings() => WatchedAppsScreen(
        apps: c.watchable,
        settings: c.settings,
        access: c.usageAccess,
        onToggle: c.setWatching,
        onSettings: c.updateSettings,
        onGrantAccess: () async {
          await const AndroidUsageSource().requestAccess();
          // No callback when the user comes back from Settings, so the check
          // runs again on the next resume as well as here.
          await Future<void>.delayed(const Duration(seconds: 1));
          await c.load();
        },
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
