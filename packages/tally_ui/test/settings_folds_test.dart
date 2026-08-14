import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// Settings opens as an index, not a scroll.
///
/// It was one flat list: every watched app, then every rule, then the theme,
/// then backup. Reaching Backup meant scrolling past the whole app list.
void main() {
  Widget screen({int apps = 3}) => MaterialApp(
        theme: TallyThemeBuilder.build(TallyTheme.blush, Brightness.light),
        home: WatchedAppsScreen(
          apps: [
            for (var i = 0; i < apps; i++)
              WatchableApp(
                packageName: 'com.app$i',
                label: 'App $i',
                recentSeconds: 600,
              ),
          ],
          settings: const LedgerSettings(),
          access: UsageAccess.granted,
          theme: TallyTheme.blush,
          themeMode: ThemeMode.light,
          onTheme: (_, __) {},
          onOpenGoals: () {},
          onOpenBackup: () {},
          onExportCsv: () async {},
        ),
      );

  testWidgets('every section starts closed', (tester) async {
    await tester.pumpWidget(screen());

    expect(find.text('WATCHED APPS'), findsOneWidget);
    expect(find.text('THE NUMBERS'), findsOneWidget);
    expect(find.text('LOOK'), findsOneWidget);
    expect(find.text('ELSEWHERE'), findsOneWidget);

    // Contents of all four are folded away.
    expect(find.text('App 0'), findsNothing);
    expect(find.text('Free minutes a day'), findsNothing);
    expect(find.text('Theme'), findsNothing);
    expect(find.text('Backup and restore'), findsNothing);
  });

  testWidgets('the app list stays closed even with nothing watched',
      (tester) async {
    // It used to open itself in this case, which made the screen open at a
    // different height depending on state. An index with one section already
    // unrolled is not an index.
    await tester.pumpWidget(screen(apps: 0));
    expect(find.text('WATCHED APPS'), findsOneWidget);
    expect(find.textContaining('Time in these apps'), findsNothing);
  });

  testWidgets('a header says what its section is set to, unopened',
      (tester) async {
    // The common question is "what is this set to", and it is answered
    // without opening anything.
    await tester.pumpWidget(screen());
    expect(find.text('nothing watched yet'), findsOneWidget);
    expect(find.text('Blush, light'), findsOneWidget);
  });

  testWidgets('tapping a header opens that section only', (tester) async {
    await tester.pumpWidget(screen());
    await tester.tap(find.text('ELSEWHERE'));
    await tester.pumpAndSettle();

    expect(find.text('Backup and restore'), findsOneWidget);
    expect(find.text('Theme'), findsNothing, reason: 'others stay closed');
  });
}
