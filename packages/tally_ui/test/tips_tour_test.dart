import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_ui/tally_ui.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
      home: Scaffold(body: child),
    );

/// Tips and the tour: the app explaining itself after first run.
void main() {
  group('pickTip', () {
    Tip? pick(
      TipSurface surface, {
      Set<Tip> seen = const {},
      int days = 0,
      bool blockingOff = true,
    }) =>
        pickTip(
          surface: surface,
          seen: seen,
          daysSinceFirstRun: days,
          blockingOff: blockingOff,
        );

    test('each screen explains itself first', () {
      expect(pick(TipSurface.today), Tip.today);
      expect(pick(TipSurface.tasks), Tip.tasks);
      expect(pick(TipSurface.focus), Tip.focus);
      expect(pick(TipSurface.balance), Tip.balance);
    });

    test('a dismissed tip never returns', () {
      expect(pick(TipSurface.tasks, seen: {Tip.tasks}), isNull);
    });

    test('the widget tip waits a couple of days, and only on Today', () {
      const seen = {Tip.today, Tip.tasks};
      expect(pick(TipSurface.today, seen: seen, days: 1), isNull);
      expect(pick(TipSurface.today, seen: seen, days: 2), Tip.widget);
      expect(pick(TipSurface.tasks, seen: seen, days: 9), isNull);
    });

    test('the blocking tip only while blocking is off', () {
      const seen = {Tip.today, Tip.widget};
      expect(pick(TipSurface.today, seen: seen, days: 4), Tip.blocking);
      expect(
        pick(TipSurface.today, seen: seen, days: 4, blockingOff: false),
        isNull,
      );
    });

    test('one at a time: the screen tip comes before a held-back one', () {
      expect(pick(TipSurface.today, days: 30), Tip.today);
    });
  });

  testWidgets('Got it retires the tip', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      wrap(TipCard(tip: Tip.today, onDismiss: () => dismissed++)),
    );
    expect(find.text(Tip.today.title), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Got it'));
    expect(dismissed, 1);
  });

  testWidgets('the tour lists every section and can replay tips',
      (tester) async {
    // Tall enough for the whole list, so every section is built at once.
    tester.view.physicalSize = const Size(800, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var replayed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
        home: TourScreen(onBack: () {}, onReplayTips: () => replayed++),
      ),
    );
    for (final section in tourSections) {
      expect(find.text(section.heading.toUpperCase()), findsOneWidget);
    }
    await tester.tap(find.bySemanticsLabel('Show the tips again'));
    expect(replayed, 1);
  });

  test('the copy keeps the app\'s voice', () {
    // Plain and factual, like every other string: no exclamation marks and
    // none of the words the library bans.
    final all = [
      for (final tip in Tip.values) ...[tip.title, tip.body],
      for (final section in tourSections)
        for (final f in section.features) ...[f.title, f.detail],
    ];
    for (final line in all) {
      expect(line, isNot(contains('!')), reason: line);
      for (final word in ['awesome', 'amazing', 'journey', 'mindset']) {
        expect(line.toLowerCase(), isNot(contains(word)), reason: line);
      }
    }
  });
}
