import 'package:flutter/material.dart';
import 'package:tally_ui/tally_ui.dart';

import 'app/tally_app.dart';
import 'data/app_database.dart';
import 'data/tally_controller.dart';
import 'platform/android_usage_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final installId = await InstallId.load();
  final controller = TallyController(
    db: openTallyDatabase(),
    installId: installId,
    usageSource: const AndroidUsageSource(),
  );

  runApp(TallyRoot(controller: controller));
}

class TallyRoot extends StatelessWidget {
  const TallyRoot({required this.controller, super.key});

  final TallyController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Tally',
        debugShowCheckedModeBanner: false,
        // Aurora is the default and the identity. The theme picker in Settings
        // will let this be changed and persisted; until then it is fixed.
        theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.light),
        darkTheme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
        themeMode: ThemeMode.dark,
        home: TallyApp(controller: controller),
      );
}
