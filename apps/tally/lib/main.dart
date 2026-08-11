import 'package:flutter/material.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

import 'app/onboarding_flow.dart';
import 'app/tally_app.dart';
import 'data/app_database.dart';
import 'data/tally_controller.dart';
import 'platform/android_usage_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openTallyDatabase();
  final installId = await InstallId.load();
  final settings = await TallyController.loadSettings(db);
  final onboarded = await OnboardingState.isDone();
  final (theme, mode) = await ThemePreference.load();

  runApp(
    TallyRoot(
      db: db,
      installId: installId,
      settings: settings,
      onboarded: onboarded,
      theme: theme,
      themeMode: mode,
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
    super.key,
  });

  final TallyDatabase db;
  final String installId;
  final LedgerSettings settings;
  final bool onboarded;
  final TallyTheme theme;
  final ThemeMode themeMode;

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

  TallyController _build() => TallyController(
        db: widget.db,
        installId: widget.installId,
        settings: _settings,
        usageSource: const AndroidUsageSource(),
      )..onSettingsChanged = (next) {
          setState(() {
            _settings = next;
            _controller = _build();
          });
        };

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Tally',
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
