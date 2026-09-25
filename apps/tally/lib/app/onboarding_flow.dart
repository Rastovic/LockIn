import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';
import 'package:vitals_notify/vitals_notify.dart';

import '../data/tally_controller.dart';
import '../platform/android_usage_source.dart';

/// Drives first run.
///
/// Holds only which step is showing; everything else it needs comes from the
/// controller, so the apps picked here are the same rows the Settings screen
/// will show afterwards.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    required this.controller,
    required this.onDone,
    super.key,
  });

  final TallyController controller;
  final Future<void> Function() onDone;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with WidgetsBindingObserver {
  OnboardingStep _step = OnboardingStep.plan;
  bool _notificationsGranted = false;

  final _notifier = LocalNotifier();

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
    // Granting usage access means leaving for system Settings, and there is no
    // callback when the user returns. Re-checking on resume is the whole
    // "verify and continue" the plan asks for.
    if (state == AppLifecycleState.resumed) c.load();
  }

  Future<void> _next() async {
    switch (_step) {
      case OnboardingStep.plan:
        setState(() => _step = OnboardingStep.earn);
      case OnboardingStep.earn:
        setState(() => _step = OnboardingStep.what);
      case OnboardingStep.what:
        setState(() => _step = OnboardingStep.usageAccess);
      case OnboardingStep.usageAccess:
        // Skipping the app picker when access was refused: it would be an
        // empty list and a second dead end.
        setState(
          () => _step = c.usageAccess == UsageAccess.granted
              ? OnboardingStep.pickApps
              : OnboardingStep.notifications,
        );
      case OnboardingStep.pickApps:
        setState(() => _step = OnboardingStep.notifications);
      case OnboardingStep.notifications:
        await widget.onDone();
    }
  }

  /// Back through the cards only. The setup steps are not stepped back into:
  /// each one either asked already or can be changed later in Settings.
  void _back() {
    final i = _step.index;
    if (!_step.isIntro || i == 0) return;
    setState(() => _step = OnboardingStep.values[i - 1]);
  }

  Future<void> _grantUsage() async {
    await const AndroidUsageSource().requestAccess();
    // Belt and braces alongside the resume handler: some launchers return
    // without a lifecycle event the app can see.
    await Future<void>.delayed(const Duration(seconds: 1));
    await c.load();
  }

  Future<void> _grantNotifications() async {
    await _notifier.initialise();
    final result = await _notifier.requestPermission();
    if (!mounted) return;
    setState(
      () => _notificationsGranted = result == NotificationPermission.granted,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // System back walks the cards backwards instead of closing the app
    // from the middle of first run.
    canPop: !_step.isIntro || _step == OnboardingStep.plan,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: OnboardingScreen(
      step: _step,
      access: c.usageAccess,
      notificationsGranted: _notificationsGranted,
      apps: [
        for (final app in c.watchable)
          WatchableAppSummary(
            packageName: app.packageName,
            label: app.label,
            recentSeconds: app.recentSeconds,
            watching: app.watching,
          ),
      ],
      onNext: _next,
      onBack: _back,
      onSkip: () => setState(() => _step = OnboardingStep.usageAccess),
      onGrantUsage: _grantUsage,
      onGrantNotifications: _grantNotifications,
      onToggleApp: (packageName, watching) {
        final app = c.watchable
            .where((a) => a.packageName == packageName)
            .firstOrNull;
        if (app != null) c.setWatching(app, watching);
      },
    ),
  );
}
