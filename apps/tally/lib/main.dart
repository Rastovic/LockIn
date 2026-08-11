import 'package:flutter/material.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

import 'app/tally_app.dart';
import 'data/app_database.dart';
import 'data/tally_controller.dart';
import 'platform/android_usage_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openTallyDatabase();
  final installId = await InstallId.load();
  final settings = await TallyController.loadSettings(db);

  runApp(TallyRoot(db: db, installId: installId, settings: settings));
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
    super.key,
  });

  final TallyDatabase db;
  final String installId;
  final LedgerSettings settings;

  @override
  State<TallyRoot> createState() => _TallyRootState();
}

class _TallyRootState extends State<TallyRoot> {
  late LedgerSettings _settings = widget.settings;
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
        // Aurora is the default and the identity. The theme picker in Settings
        // will let this be changed and persisted; until then it is fixed.
        theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.light),
        darkTheme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
        themeMode: ThemeMode.dark,
        home: TallyApp(
          key: ValueKey(_settings.hashCode),
          controller: _controller,
        ),
      );
}
