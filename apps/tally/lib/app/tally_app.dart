import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vitals_archive/vitals_archive.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

import '../data/app_database.dart';
import '../data/tally_controller.dart';
import '../platform/android_links.dart';
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
  /// Which task kind the Tasks tab is filtered to, or null for All.
  ///
  /// Opens on All: after a day of real use, landing on one of four buckets and
  /// having to guess which one a task was filed under is the wrong first
  /// impression of the screen.
  TaskKind? _segment;

  /// Showing captured tasks that have not been sorted yet.
  bool _inbox = false;
  bool _showBalance = false;

  /// Tips dismissed so far. Empty until read, and nothing is shown until then
  /// so a tip already dismissed never flashes up on launch.
  Set<Tip> _seenTips = const {};
  int _daysSinceFirstRun = 0;
  bool _tipsLoaded = false;

  TallyController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.addListener(_onChanged);
    c.load();
    unawaited(_loadTips());
  }

  Future<void> _loadTips() async {
    final state = await TipsState.load(now: c.now);
    if (!mounted) return;
    setState(() {
      _seenTips = state.seen;
      _daysSinceFirstRun = state.daysSinceFirstRun;
      _tipsLoaded = true;
    });
  }

  Widget? _tipCard(TipSurface? surface) {
    if (!_tipsLoaded || surface == null) return null;
    final tip = pickTip(
      surface: surface,
      seen: _seenTips,
      daysSinceFirstRun: _daysSinceFirstRun,
      blockingOff: c.blockMode == BlockMode.off,
    );
    if (tip == null) return null;
    return TipCard(
      key: ValueKey(tip),
      tip: tip,
      onDismiss: () {
        setState(() => _seenTips = {..._seenTips, tip});
        unawaited(TipsState.markSeen(_seenTips));
      },
    );
  }

  /// A full screen with its tip under it. The screen gives up its bottom
  /// inset to the card, which sits above the system bar in its place.
  Widget _withTip(Widget screen, TipSurface surface) {
    final card = _tipCard(surface);
    if (card == null) return screen;
    return Material(
      color: Theme.of(context).extension<TallyTokens>()!.bg,
      child: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: screen,
            ),
          ),
          SafeArea(top: false, child: card),
        ],
      ),
    );
  }

  /// The tab's own surface, or null on a screen opened from it.
  TipSurface? get _tabSurface => switch (_tab) {
        0 => TipSurface.today,
        1 => TipSurface.tasks,
        2 => TipSurface.stats,
        _ => _showGoals || _showAccuracy || _showTour
            ? null
            : TipSurface.settings,
      };

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
      return _withTip(
        BalanceScreen(
          model: c.balanceModel,
          onClose: () => setState(() => _showBalance = false),
          onTreat: c.balanceModel.savingsSeconds > 0 ? _openTreat : null,
        ),
        TipSurface.balance,
      );
    }

    if (c.focus case final run?) {
      final task = run.taskId == null
          ? null
          : c.tasks.where((t) => t.id == run.taskId).firstOrNull;
      return _withTip(
        FocusScreen(
          run: run,
          earnRatio: c.settings.earnRatio,
          taskTitle: task?.title ?? 'Focus',
          stickerId: task?.stickerId,
          onPause: c.pauseFocus,
          onResume: c.resumeFocus,
          onExtend: c.extendFocus,
          onGiveUp: c.endFocus,
          onComplete: c.endFocus,
          alarmBlocked: c.focusAlarmBlocked,
          alarmImprecise: c.focusAlarmImprecise,
          onFixAlarm: () => unawaited(c.requestExactAlarms()),
        ),
        TipSurface.focus,
      );
    }

    return Scaffold(
      body: switch (_tab) {
        0 => _buildToday(),
        1 => _buildTasks(),
        2 => _buildStats(),
        _ => _buildSettings(),
      },
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?_tipCard(_tabSurface),
          NavigationBar(
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
        ],
      ),
    );
  }

  Widget _buildToday() => TodayScreen(
        model: c.today,
        onToggle: c.toggle,
        onReorder: c.reorder,
        onStartFocus: (entry) => _startTaskFocus(
          c.tasks.where((t) => t.id == entry.taskId).firstOrNull,
        ),
        onStartSession: () => _askDuration(),
        onAcceptHabit: (habit) =>
            c.addToToday([habit.id], source: PlanSource.habit),
        onAcceptSuggestion: c.acceptSuggestion,
        onDismissSuggestion: c.dismissSuggestion,
        onOpenPool: _openPool,
        onOpenBalance: () => setState(() => _showBalance = true),
      );

  /// Play on a task starts the clock. It does not ask.
  ///
  /// The estimate written on the task is the answer: someone who put "45 min"
  /// on it decided how long when they wrote it, and asking again at the moment
  /// they press play is the same decision twice. Pressing play on a row is a
  /// commitment to that row, not the opening of a form.
  ///
  /// The sheet stays where the question is real. "Start focusing" carries no
  /// task and so has no length to read, and a task nobody gave an estimate has
  /// none either - both still ask.
  void _startTaskFocus(Task? task) {
    final minutes = task?.estimateMinutes;
    if (task == null || minutes == null) {
      _askDuration(taskId: task?.id, taskTitle: task?.title);
      return;
    }
    c.startFocus(taskId: task.id, minutes: minutes);
  }

  /// Asks how long before the clock starts.
  ///
  /// Reached from "Start focusing", and from a task with no estimate to go on.
  /// The length used to be decided for the user everywhere - the task's
  /// estimate, or twenty-five minutes - and a timer whose length nobody chose
  /// is one that gets abandoned halfway. Where there is an estimate, the choice
  /// was already made; where there is not, it is made here.
  Future<void> _askDuration({
    String? taskId,
    String? taskTitle,
    int? suggestedMinutes,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DurationSheet(
        taskTitle: taskTitle,
        suggestedMinutes: suggestedMinutes,
        onStart: (minutes) {
          Navigator.of(sheetContext).pop();
          c.startFocus(taskId: taskId, minutes: minutes);
        },
      ),
    );
  }

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

  /// The Stats tab: one switcher, three faces, and the collection behind
  /// Stickers.
  ///
  /// Statement, Insights and Stickers used to be two pills floating at the
  /// bottom of the Statement in a Stack. The list scrolled underneath them, so
  /// they sat on top of whatever text happened to be at the bottom of the
  /// screen - and being findable only by scrolling to the end of a list is a
  /// poor way to expose a third of the tab. A switcher at the top costs the
  /// same space, never covers content, and shows what else is there before you
  /// have read anything.
  Widget _buildStats() {
    if (_statsView == _StatsView.collection) return _buildCollection();

    return Scaffold(
      backgroundColor: context.tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _StatsSwitcher(
              selected: _statsView,
              onChanged: (view) => setState(() => _statsView = view),
            ),
          ),
          Expanded(
            // The switcher already consumed the status bar inset. Without
            // this the sub-screen's own SafeArea adds it a second time and
            // opens a gap the height of the notch under the switcher.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: switch (_statsView) {
                _StatsView.stickers => _buildStickerSheet(),
                _StatsView.insights => _buildInsights(),
                _ => _buildStatement(),
              },
            ),
          ),
        ],
      ),
    );
  }

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
          return InsightsScreen(model: model);
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
          return StatementScreen(
            model: model,
            onPeriod: (period) => setState(() => _period = period),
          );
        },
      );

  bool _showGoals = false;
  bool _showAccuracy = false;
  bool _showTour = false;

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

  bool _backupBusy = false;

  Future<void> _openBackup() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BackupSheet(
        busy: _backupBusy,
        onExport: () async {
          Navigator.of(sheetContext).pop();
          await _exportArchive();
        },
        onRestore: () async {
          Navigator.of(sheetContext).pop();
          await _restoreArchive();
        },
      ),
    );
  }

  /// Writes the archive and hands it to the system share sheet.
  ///
  /// Sharing rather than saving to a fixed folder: the user picks Drive, email
  /// or a file manager, which means the backup ends up somewhere they will
  /// actually look for it, and no storage permission is needed.
  Future<void> _exportArchive() async {
    final bytes = await c.exportArchive(appVersion: '0.1.0');
    final dir = await getTemporaryDirectory();
    final name = ArchiveManifest.fileNameFor(
      appSlug: 'tally',
      exportedAtLocal: c.now.toLocal(),
    );
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [name]),
    );
  }

  /// Picks a file, shows what is in it, and only then writes anything.
  Future<void> _restoreArchive() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    final bytes = picked?.files.singleOrNull?.bytes;
    if (bytes == null || !mounted) return;

    final read = c.previewArchive(bytes);
    if (read.error != null) {
      await _showRestoreResult(error: read.error);
      return;
    }

    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Deliberately not dismissible by tapping away: this is the last point
      // before a year of history is replaced.
      isDismissible: false,
      builder: (sheetContext) => RestoreConfirmSheet(
        preview: read.preview!,
        onConfirm: () => Navigator.of(sheetContext).pop(true),
        onCancel: () => Navigator.of(sheetContext).pop(false),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _backupBusy = true);
    final result = await c.restoreArchive(bytes);
    if (!mounted) return;
    setState(() => _backupBusy = false);

    await _showRestoreResult(
      verification: result.verification,
      error: result.error,
    );
  }

  Future<void> _showRestoreResult({
    ImportVerification? verification,
    ArchiveError? error,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RestoreResultSheet(
        verification: verification,
        error: error,
        onClose: () => Navigator.of(sheetContext).pop(),
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

  Widget _buildTour() => TourScreen(
        onBack: () => setState(() => _showTour = false),
        onReplayTips: () async {
          await TipsState.reset();
          if (!mounted) return;
          setState(() {
            _seenTips = const {};
            _showTour = false;
          });
        },
      );

  Widget _buildSettings() => _showTour
      ? _buildTour()
      : _showAccuracy
      ? _buildAccuracy()
      : _showGoals
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
        onOpenTour: () => setState(() => _showTour = true),
        onPrivacyPolicy: () => unawaited(
          const AndroidLinks().open(AndroidLinks.privacyPolicyUrl),
        ),
        onCheckNumbers: () => setState(() => _showAccuracy = true),
        onExportCsv: _exportCsv,
        onOpenBackup: _openBackup,
        blocking: c.blockMode,
        blockerOn: c.blockerOn,
        onBlocking: _setBlocking,
        onOpenBlockerSettings: _openBlockerSettings,
      );

  /// Leaving off starts with the disclosure, every time.
  ///
  /// Play requires the reason for an accessibility service to be shown, and
  /// agreed to, in the app before the user is sent to the system switch. It is
  /// also the same rule the usage-access step follows: the reason before the
  /// ask.
  Future<void> _setBlocking(BlockMode mode) async {
    // Moving between remind and block, or turning it off, changes nothing
    // about what the service can see, so there is nothing new to disclose.
    if (mode == BlockMode.off || c.blockMode != BlockMode.off) {
      await c.setBlockMode(mode);
      return;
    }
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).extension<TallyTokens>()!.bg,
      builder: (context) => const _BlockingDisclosure(),
    );
    if (agreed != true) return;
    await c.setBlockMode(mode);
    if (!c.blockerOn) await _openBlockerSettings();
  }

  Future<void> _openBlockerSettings() async {
    await c.openBlockerSettings();
    // No callback when the user comes back from Settings; the resume reload
    // re-checks the switch.
  }

  /// The one check the app cannot run on itself.
  Widget _buildAccuracy() => FutureBuilder<List<AccuracyDay>>(
        future: c.accuracyDays(),
        builder: (context, snapshot) => AccuracyScreen(
          days: snapshot.data ?? const [],
          onBack: () => setState(() => _showAccuracy = false),
          onReport: c.recordAccuracy,
        ),
      );

  Widget _buildTasks() => ManageTasksScreen(
        model: c.manage,
        segment: _segment,
        inbox: _inbox,
        onInbox: () => setState(() => _inbox = true),
        onSegment: (kind) => setState(() {
          _segment = kind;
          _inbox = false;
        }),
        onCreate: () => _openSheet(initialKind: _segment ?? TaskKind.oneoff),
        onEdit: (task) => _openSheet(existing: task),
        onDelete: _confirmDeleteTask,
        onAddToToday: (task) => c.addToToday([task.id]),
        onStartFocus: (task) => _startTaskFocus(task),
        onCreateProject: _openProjectSheet,
        onAddToProject: (project) => _openSheet(
          initialKind: TaskKind.projectTask,
          projectId: project.id,
          projectName: project.name,
        ),
        onRenameProject: (project) => _openProjectSheet(existing: project),
        onDeleteProject: _confirmDeleteProject,
      );

  /// Creating or renaming a project.
  ///
  /// A name and nothing else. A project holds no time, no dates and no
  /// progress, so there is nothing else to ask for.
  Future<void> _openProjectSheet({Project? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: NameSheet(
          title: existing == null ? 'New project' : 'Rename project',
          hint: 'Dissertation',
          controller: controller,
          saveLabel: existing == null ? 'Create' : 'Save',
          onSave: (name) {
            Navigator.of(sheetContext).pop();
            if (existing == null) {
              c.createProject(name);
            } else {
              c.renameProject(existing, name);
            }
          },
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _confirmDeleteProject(Project project) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ConfirmSheet(
        title: 'Delete ${project.name}?',
        // The reassurance that matters: someone tidying a project list is not
        // asking to lose the work inside it.
        detail: 'The tasks in it are kept. They stop being filed under a '
            'project, and nothing else changes.',
        confirmLabel: 'Delete the project',
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          c.deleteProject(project.id);
        },
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  /// Reached by holding a row on the Tasks tab, so deleting no longer means
  /// opening the task and scrolling to the bottom of its sheet.
  Future<void> _confirmDeleteTask(Task task) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ConfirmSheet(
        title: 'Delete ${task.title}?',
        detail: 'It leaves your lists and today\'s plan.',
        confirmLabel: 'Delete task',
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          c.deleteTask(task.id);
        },
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  Future<void> _openSheet({
    Task? existing,
    TaskKind? initialKind,
    String? projectId,
    String? projectName,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskSheet(
        existing: existing,
        initialKind: initialKind ?? TaskKind.oneoff,
        projectId: projectId,
        projectName: projectName,
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

/// The Stats tab's three faces, as a row of chips.
class _StatsSwitcher extends StatelessWidget {
  const _StatsSwitcher({required this.selected, required this.onChanged});

  final _StatsView selected;
  final ValueChanged<_StatsView> onChanged;

  static const _faces = [
    (_StatsView.statement, 'Statement'),
    (_StatsView.insights, 'Insights'),
    (_StatsView.stickers, 'Stickers'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          for (final (view, label) in _faces) ...[
            Semantics(
              button: true,
              selected: selected == view,
              label: label,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(view),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == view
                        ? tokens.states.solvent
                        : tokens.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: text.bodyLarge?.copyWith(
                      color: selected == view ? tokens.bg : tokens.inkMuted,
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

/// What the accessibility service does, stated before it is switched on.
class _BlockingDisclosure extends StatelessWidget {
  const _BlockingDisclosure();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TallyTokens>()!;
    final text = Theme.of(context).textTheme;

    Widget button(String label, {required bool primary, required bool value}) =>
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(value),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? tokens.states.solvent : tokens.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: text.bodyLarge?.copyWith(
                  color: primary ? tokens.bg : tokens.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step in at zero', style: text.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'LockIn uses Android\'s accessibility service for this. It '
              'only sees which app is opened, so it can show a page over the '
              'apps you watch once your minutes run out.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'It does not read what is on screen or what you type, and '
              'nothing is sent anywhere. Turn it off here or in Settings at '
              'any time.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            button('Agree and open Settings', primary: true, value: true),
            const SizedBox(height: 8),
            button('Not now', primary: false, value: false),
          ],
        ),
      ),
    );
  }
}
