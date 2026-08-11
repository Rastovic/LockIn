import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

final start = DateTime.utc(2026, 8, 11, 9);
DateTime at(int minutes, [int seconds = 0]) =>
    start.add(Duration(minutes: minutes, seconds: seconds));

FocusRun runOf({int minutes = 25, bool phoneDown = false}) => FocusRun(
      id: 'r',
      startedAt: start,
      planned: Duration(minutes: minutes),
      taskId: 'gym',
      phoneDownRequested: phoneDown,
    );

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
      home: child,
    );

void main() {
  group('the countdown', () {
    testWidgets('shows the time left, not the time spent', (tester) async {
      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf(),
            earnRatio: 1,
            taskTitle: 'Gym',
            clock: () => at(10),
          ),
        ),
      );
      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('comes from the clock, not from how many ticks fired',
        (tester) async {
      // A block backgrounded for twenty minutes is twenty minutes further
      // along when the screen returns. A tick-accumulated timer would show
      // almost the full 25 still remaining.
      var now = start;
      await tester.pumpWidget(
        wrap(FocusScreen(run: runOf(), earnRatio: 1, clock: () => now)),
      );
      expect(find.text('25:00'), findsOneWidget);

      now = at(20);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('stops at zero rather than going negative', (tester) async {
      await tester.pumpWidget(
        wrap(FocusScreen(run: runOf(), earnRatio: 1, clock: () => at(90))),
      );
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('reports completion once, not on every tick', (tester) async {
      var completions = 0;
      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf(minutes: 1),
            earnRatio: 1,
            clock: () => at(5),
            onComplete: () => completions++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(completions, 1);
    });
  });

  group('the deal is stated out loud', () {
    testWidgets('says what the block earns at 1:1', (tester) async {
      await tester.pumpWidget(
        wrap(FocusScreen(run: runOf(), earnRatio: 1, clock: () => at(1))),
      );
      expect(
        find.text('25 min focused = 25 min of scrolling'),
        findsOneWidget,
      );
    });

    testWidgets('stays honest at a stricter ratio', (tester) async {
      // A 2:1 user is told they earn 12, not 25. The rate on screen must be
      // the rate that gets paid.
      await tester.pumpWidget(
        wrap(FocusScreen(run: runOf(), earnRatio: 0.5, clock: () => at(1))),
      );
      expect(
        find.text('25 min focused = 12 min of scrolling'),
        findsOneWidget,
      );
    });

    testWidgets('shows the running total earned', (tester) async {
      await tester.pumpWidget(
        wrap(FocusScreen(run: runOf(), earnRatio: 1, clock: () => at(10))),
      );
      expect(find.text('10 min earned so far'), findsOneWidget);
    });
  });

  group('pausing', () {
    testWidgets('the clock holds and the button offers Resume', (tester) async {
      final paused = runOf().pause(at(10));
      await tester.pumpWidget(
        wrap(FocusScreen(run: paused, earnRatio: 1, clock: () => at(30))),
      );
      expect(find.text('15:00'), findsOneWidget, reason: 'frozen at 10 min in');
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('pause and resume are reported', (tester) async {
      var paused = 0;
      var resumed = 0;

      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf(),
            earnRatio: 1,
            clock: () => at(5),
            onPause: () => paused++,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Pause'));

      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf().pause(at(5)),
            earnRatio: 1,
            clock: () => at(6),
            onResume: () => resumed++,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Resume'));

      expect(paused, 1);
      expect(resumed, 1);
    });
  });

  group('extending', () {
    testWidgets('offers +5, +10 and +20', (tester) async {
      final added = <Duration>[];
      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf(),
            earnRatio: 1,
            clock: () => at(5),
            onExtend: added.add,
          ),
        ),
      );

      for (final label in ['Add 5 minutes', 'Add 10 minutes',
          'Add 20 minutes']) {
        await tester.tap(find.bySemanticsLabel(label));
      }
      expect(added, [
        const Duration(minutes: 5),
        const Duration(minutes: 10),
        const Duration(minutes: 20),
      ]);
    });
  });

  group('giving up', () {
    testWidgets('says what it costs, and it costs nothing', (tester) async {
      var gaveUp = 0;
      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf(),
            earnRatio: 1,
            clock: () => at(5),
            onGiveUp: () => gaveUp++,
          ),
        ),
      );
      expect(find.text('Give up · costs nothing'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Give up · costs nothing'));
      expect(gaveUp, 1);
    });
  });

  group('phone down', () {
    testWidgets('states the bonus while the screen stays off', (tester) async {
      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf(phoneDown: true),
            earnRatio: 1,
            clock: () => at(5),
          ),
        ),
      );
      expect(find.textContaining('pays 1.5x'), findsOneWidget);
    });

    testWidgets('an unlock is reported honestly, without scolding',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          FocusScreen(
            run: runOf(phoneDown: true)
                .copyWith(screenUnlockedDuringBlock: true),
            earnRatio: 1,
            clock: () => at(5),
          ),
        ),
      );
      final notice = find.textContaining('pays 1.0x');
      expect(notice, findsOneWidget);
      final text = tester.widget<Text>(notice).data!;
      // An honest note, not a telling-off.
      expect(text, isNot(contains('!')));
      for (final word in ['cheat', 'failed', 'lost', 'should']) {
        expect(text.toLowerCase(), isNot(contains(word)));
      }
    });
  });

  group('the completion screen', () {
    testWidgets('shows where the minutes went when there was a debt',
        (tester) async {
      // Earnings pay debt first, so a user who was 20 down and earned 25 sees
      // the split rather than wondering why the balance only moved by five.
      await tester.pumpWidget(
        wrap(
          const FocusCompleteScreen(
            creditedSeconds: 25 * 60,
            debtClearedSeconds: 20 * 60,
            newBalanceSeconds: 5 * 60,
          ),
        ),
      );
      expect(find.text('25'), findsOneWidget);
      expect(find.text('went to clearing your debt'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
    });

    testWidgets('hides the debt line when there was no debt', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FocusCompleteScreen(
            creditedSeconds: 25 * 60,
            debtClearedSeconds: 0,
            newBalanceSeconds: 45 * 60,
          ),
        ),
      );
      expect(find.text('went to clearing your debt'), findsNothing);
    });

    testWidgets('makes the earn cap visible rather than mysterious',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const FocusCompleteScreen(
            creditedSeconds: 30 * 60,
            debtClearedSeconds: 0,
            newBalanceSeconds: 90 * 60,
            cappedSeconds: 15 * 60,
          ),
        ),
      );
      expect(find.textContaining('earn cap'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('offers keep going, mark done and stop', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          FocusCompleteScreen(
            creditedSeconds: 25 * 60,
            debtClearedSeconds: 0,
            newBalanceSeconds: 25 * 60,
            onKeepGoing: () => tapped.add('keep'),
            onMarkDone: () => tapped.add('done'),
            onStopForToday: () => tapped.add('stop'),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Keep going · +20'));
      await tester.tap(find.bySemanticsLabel('Mark done'));
      await tester.tap(find.bySemanticsLabel('Stop for today'));
      expect(tapped, ['keep', 'done', 'stop']);
    });

    testWidgets('no copy on either screen cheers or scolds', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FocusCompleteScreen(
            creditedSeconds: 25 * 60,
            debtClearedSeconds: 0,
            newBalanceSeconds: 25 * 60,
          ),
        ),
      );
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(texts, isNot(contains('!')));
      for (final word in ['great', 'well done', 'nice', 'amazing', 'crushed']) {
        expect(texts, isNot(contains(word)), reason: word);
      }
    });
  });
}
