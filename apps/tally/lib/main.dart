import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';
import 'package:vitals_ads/vitals_ads.dart';
import 'package:vitals_notify/vitals_notify.dart';

import 'app/ads.dart';
import 'app/onboarding_flow.dart';
import 'app/tally_app.dart';
import 'data/app_database.dart';
import 'data/tally_controller.dart';
import 'platform/android_focus_notice.dart';
import 'platform/android_home_widget.dart';
import 'platform/android_usage_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openTallyDatabase();
  final installId = await InstallId.load();
  final settings = await TallyController.loadSettings(db);
  final onboarded = await OnboardingState.isDone();
  final (theme, mode) = await ThemePreference.load();

  // Started, not awaited: consent and the SDK take a network round trip, and
  // the first frame must not wait on an ad. Everything the ads layer is asked
  // before it finishes answers "no ad", which is the correct answer anyway.
  final ads = AdsController(gateway: AdMobGateway());
  unawaited(ads.start());

  runApp(
    TallyRoot(
      db: db,
      installId: installId,
      settings: settings,
      onboarded: onboarded,
      theme: theme,
      themeMode: mode,
      ads: ads,
    ),
  );
}

/// Owns the controller so a settings change can rebuild it.
///
/// [LedgerSettings] is injected once, because the ledger is derived from them:
/// changing the earn rate changes what every past day was worth, and the
/// cleanest way to apply that is to rebuild and recompute rather than to mutate
/// a rule under a running engine.
class TallyRoot extends StatefulWidget {
  const TallyRoot({
    required this.db,
    required this.installId,
    required this.settings,
    required this.onboarded,
    required this.theme,
    required this.themeMode,
    required this.ads,
    super.key,
  });

  final TallyDatabase db;
  final String installId;
  final LedgerSettings settings;
  final bool onboarded;
  final TallyTheme theme;
  final ThemeMode themeMode;
  final AdsController ads;

  @override
  State<TallyRoot> createState() => _TallyRootState();
}

class _TallyRootState extends State<TallyRoot> {
  late LedgerSettings _settings = widget.settings;
  late bool _onboarded = widget.onboarded;
  late TallyTheme _theme = widget.theme;
  late ThemeMode _mode = widget.themeMode;

  void _setTheme(TallyTheme theme, ThemeMode mode) {
    setState(() {
      _theme = theme;
      _mode = mode;
    });
    ThemePreference.save(theme, mode);
  }
  late TallyController _controller = _build();

  /// One notifier for the app's lifetime.
  ///
  /// Built once rather than per controller: the controller is rebuilt whenever
  /// a setting changes, and a fresh plugin instance each time would lose track
  /// of what it had already scheduled.
  final _notifier = LocalNotifier();

  TallyController _build() => TallyController(
        db: widget.db,
        installId: widget.installId,
        settings: _settings,
        usageSource: const AndroidUsageSource(),
        notifier: _notifier,
        homeWidget: const AndroidHomeWidget(),
        focusNotice: const AndroidFocusNotice(),
      )..onSettingsChanged = (next) {
          setState(() {
            _settings = next;
            _controller = _build();
          });
        };

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'lockIn',
        debugShowCheckedModeBanner: false,
        theme: TallyThemeBuilder.build(_theme, Brightness.light),
        darkTheme: TallyThemeBuilder.build(_theme, Brightness.dark),
        themeMode: _mode,
        home: _onboarded
            ? TallyApp(
                key: ValueKey(_settings.hashCode),
                controller: _controller,
                theme: _theme,
                themeMode: _mode,
                onTheme: _setTheme,
                ads: widget.ads,
              )
            : OnboardingFlow(
                controller: _controller,
                onDone: () async {
                  await OnboardingState.markDone();
                  if (mounted) setState(() => _onboarded = true);
                },
              ),
      );
}
