import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  const TallyApp({
    required this.controller,
    required this.theme,
    required this.themeMode,
    required this.onTheme,
    super.key,
  });

  final TallyController controller;
  final TallyTheme theme;
  final ThemeMode themeMode;
  final void Function(TallyTheme, ThemeMode) onTheme;

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
        onTreat: c.balanceModel.savingsSeconds > 0 ? _openTreat : null,
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

  /// Spending savings on something that is not a screen.
  Future<void> _openTreat() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TreatSheet(
        savingsSeconds: c.balanceModel.savingsSeconds,
        onTreat: (label, seconds) {
          Navigator.of(sheetContext).pop();
          c.treatYourself(label, seconds);
        },
      ),
    );
  }

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
  _StatsView _statsView = _StatsView.statement;

  Widget _buildStats() => switch (_statsView) {
        _StatsView.statement => _buildStatement(),
        _StatsView.stickers => _buildStickerSheet(),
        _StatsView.collection => _buildCollection(),
        _StatsView.insights => _buildInsights(),
      };

  Widget _buildInsights() => FutureBuilder<InsightsModel>(
        future: c.insights(),
        builder: (context, snapshot) {
          final model = snapshot.data;
          if (model == null) {
            return Scaffold(
              backgroundColor: context.tokens.bg,
              body: const SizedBox(),
            );
          }
          return InsightsScreen(
            model: model,
            onBack: () => setState(() => _statsView = _StatsView.statement),
          );
        },
      );

  Widget _buildStickerSheet() => FutureBuilder<StickerSheetModel>(
        future: c.stickerSheet(),
        builder: (context, snapshot) {
          final model = snapshot.data;
          if (model == null) {
            return Scaffold(
              backgroundColor: context.tokens.bg,
              body: const SizedBox(),
            );
          }
          return StickerSheetScreen(
            model: model,
            onOpenCollection: () =>
                setState(() => _statsView = _StatsView.collection),
          );
        },
      );

  Widget _buildCollection() => FutureBuilder<UnlockContext>(
        future: c.unlockContext(),
        builder: (context, snapshot) {
          final unlock = snapshot.data;
          if (unlock == null) {
            return Scaffold(
              backgroundColor: context.tokens.bg,
              body: const SizedBox(),
            );
          }
          return StickerCollectionScreen(
            context_: unlock,
            onClose: () => setState(() => _statsView = _StatsView.stickers),
          );
        },
      );

  Widget _buildStatement() => FutureBuilder<StatementModel>(
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
          return Stack(
            children: [
              StatementScreen(
                model: model,
                onPeriod: (period) => setState(() => _period = period),
              ),
              // The sheet is one tap from the statement rather than a fifth
              // tab: it is the same question - what happened - asked in the
              // other currency.
              Positioned(
                left: 16,
                bottom: 16,
                child: Semantics(
                  button: true,
                  label: 'Insights',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _statsView = _StatsView.insights),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.tokens.surfaceStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Insights',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Semantics(
                  button: true,
                  label: 'Sticker sheet',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _statsView = _StatsView.stickers),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.tokens.surfaceStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Stickers',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

  bool _showGoals = false;

  Widget _buildGoals() => GoalsScreen(
        goals: c.goals,
        onBack: () => setState(() => _showGoals = false),
        onAdd: (scope) => _openGoalSheet(scope: scope),
        onEdit: (goal) => _openGoalSheet(scope: goal.scope, existing: goal),
        onAchieve: (goal) => c.achieveGoal(goal.id),
      );

  Future<void> _openGoalSheet({
    required GoalScope scope,
    Goal? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GoalSheet(
        scope: scope,
        existing: existing,
        onSave: (title, note) {
          Navigator.of(sheetContext).pop();
          c.saveGoal(
            scope: scope,
            title: title,
            note: note,
            existingId: existing?.id,
          );
        },
        onDelete: existing == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                c.deleteGoal(existing.id);
              },
      ),
    );
  }

  /// Writes the numbers to a file and hands it to the system share sheet.
  ///
  /// Never uploaded anywhere: the file is written on the device and passed to
  /// whatever the user picks, which is the same promise the whole app makes.
  Future<void> _exportCsv() async {
    final csv = await c.exportCsv(_period);
    final dir = await getTemporaryDirectory();
    final local = c.now.toLocal();
    final name = 'tally-${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(csv);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [name]),
    );
  }

  Widget _buildSettings() => _showGoals
      ? _buildGoals()
      : WatchedAppsScreen(
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
        theme: widget.theme,
        themeMode: widget.themeMode,
        onTheme: widget.onTheme,
        onOpenGoals: () => setState(() => _showGoals = true),
        onExportCsv: _exportCsv,
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

/// Which face of the Stats tab is showing.
enum _StatsView { statement, stickers, collection, insights }
