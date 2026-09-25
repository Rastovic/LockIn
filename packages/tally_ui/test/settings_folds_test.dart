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

  group('blocking', () {
    Widget blockingScreen({
      BlockMode? blocking,
      bool blockerOn = false,
      ValueChanged<BlockMode>? onBlocking,
      VoidCallback? onOpen,
      UsageAccess access = UsageAccess.granted,
    }) =>
        MaterialApp(
          theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
          home: WatchedAppsScreen(
            apps: const [],
            settings: const LedgerSettings(),
            access: access,
            blocking: blocking,
            blockerOn: blockerOn,
            onBlocking: onBlocking,
            onOpenBlockerSettings: onOpen,
          ),
        );

    testWidgets('hidden where there is no blocker', (tester) async {
      await tester.pumpWidget(blockingScreen());
      expect(find.text('BLOCKING'), findsNothing);
    });

    testWidgets('hidden without usage access, which it counts from',
        (tester) async {
      await tester.pumpWidget(
        blockingScreen(blocking: BlockMode.off, access: UsageAccess.denied),
      );
      expect(find.text('BLOCKING'), findsNothing);
    });

    testWidgets('the header says whether it can actually block',
        (tester) async {
      await tester.pumpWidget(blockingScreen(blocking: BlockMode.off));
      expect(find.text('off'), findsOneWidget);

      await tester.pumpWidget(blockingScreen(blocking: BlockMode.block));
      expect(find.text('needs a switch in Settings'), findsOneWidget);

      await tester.pumpWidget(
        blockingScreen(blocking: BlockMode.block, blockerOn: true),
      );
      expect(find.text('block at zero'), findsOneWidget);

      await tester.pumpWidget(
        blockingScreen(blocking: BlockMode.remind, blockerOn: true),
      );
      expect(find.text('remind at zero'), findsOneWidget);
    });

    testWidgets('picking a mode hands it to the app', (tester) async {
      BlockMode? picked;
      await tester.pumpWidget(
        blockingScreen(blocking: BlockMode.off, onBlocking: (v) => picked = v),
      );
      await tester.tap(find.text('BLOCKING'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remind'));
      expect(picked, BlockMode.remind);
      await tester.tap(find.text('Block'));
      expect(picked, BlockMode.block);
    });

    testWidgets('on without the system switch, the way to it is offered',
        (tester) async {
      var opened = false;
      await tester.pumpWidget(
        blockingScreen(blocking: BlockMode.block, onOpen: () => opened = true),
      );
      await tester.tap(find.text('BLOCKING'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Settings'));
      expect(opened, isTrue);
    });

    testWidgets('the rules line stops promising nothing is blocked',
        (tester) async {
      await tester.pumpWidget(
        blockingScreen(blocking: BlockMode.block, blockerOn: true),
      );
      await tester.tap(find.text('THE NUMBERS'));
      await tester.pumpAndSettle();
      expect(find.textContaining('nothing is ever blocked'), findsNothing);
      expect(find.textContaining('covered at zero'), findsOneWidget);
    });
  });
}
