import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

final now = DateTime.utc(2026, 8, 11, 9);

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
      home: child,
    );

BalanceScreenModel balance({
  int spendable = 2520,
  int earned = 3300,
  int spent = 2580,
  int savings = 11400,
  int streak = 6,
  int best = 11,
  int grace = 0,
  int unrepayable = 0,
  List<AppSpend> spendByApp = const [],
}) =>
    BalanceScreenModel(
      spendableSeconds: spendable,
      earnedSeconds: earned,
      spentSeconds: spent,
      savingsSeconds: savings,
      solvencyStreak: streak,
      bestStreak: best,
      graceRemainingSeconds: grace,
      unrepayableSeconds: unrepayable,
      spendByApp: spendByApp,
    );

Task task(
  String id, {
  String? sticker,
  int? estimate,
  TaskKind kind = TaskKind.oneoff,
  DateTime? created,
}) =>
    Task(
      id: id,
      kind: kind,
      title: id,
      createdAt: created ?? DateTime.utc(2026, 8, 1),
      stickerId: sticker,
      estimateMinutes: estimate,
    );

void main() {
  group('the balance screen', () {
    testWidgets('shows the number, the three stats and the streak',
        (tester) async {
      await tester.pumpWidget(wrap(BalanceScreen(model: balance())));

      // Twice: the headline figure, and the total line of the sum that
      // explains it. Both are the same number by design.
      expect(find.text('42'), findsNWidgets(2));
      expect(find.text('minutes left today'), findsOneWidget);
      expect(find.text('55'), findsOneWidget, reason: 'earned');
      expect(find.text('43'), findsOneWidget, reason: 'spent');
      expect(find.text('3h10'), findsOneWidget, reason: 'saved');
      expect(find.text('6 solvent days in a row · best 11'), findsOneWidget);
    });

    testWidgets('borrowing changes the number and the word', (tester) async {
      await tester.pumpWidget(
        wrap(BalanceScreen(model: balance(spendable: -1080, streak: 0))),
      );
      expect(find.text('−18'), findsNWidgets(2));
      expect(find.text('minutes borrowed'), findsOneWidget);
      // The best is still stated when the current streak is gone. It is a
      // fact rather than a rebuke, and it is the number that says the streak
      // is reachable.
      expect(find.text('No streak running · best 11'), findsOneWidget);
    });

    testWidgets('grace is stated only while it is actually running',
        (tester) async {
      // A permanent line saying "5 minutes of grace" would read as an
      // allowance rather than as the one-off it is.
      await tester.pumpWidget(
        wrap(BalanceScreen(model: balance(spendable: 0, grace: 180))),
      );
      expect(find.textContaining('3 minutes of grace'), findsOneWidget);

      await tester.pumpWidget(
        wrap(BalanceScreen(model: balance(spendable: 2520, grace: 300))),
      );
      expect(find.textContaining('grace'), findsNothing);
    });

    testWidgets('unrepayable overspend is shown separately from the debt',
        (tester) async {
      // The floor means the number owed stops at -60 while the real minutes
      // keep being recorded. Folding them together would misstate both.
      await tester.pumpWidget(
        wrap(
          BalanceScreen(
            model: balance(spendable: -3600, unrepayable: 1800),
          ),
        ),
      );
      expect(find.text('−60'), findsNWidgets(2));
      expect(find.textContaining('30 minutes went unrecorded'), findsOneWidget);
    });

    testWidgets('per-app spend lists the worst first', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceScreen(
            model: balance(
              spendByApp: const [
                AppSpend(
                  packageName: 'a',
                  label: 'TikTok',
                  seconds: 1680,
                ),
                AppSpend(
                  packageName: 'b',
                  label: 'Instagram',
                  seconds: 900,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('28m'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
    });

    testWidgets('an app missing from this phone is greyed, not dropped',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceScreen(
            model: balance(
              spendByApp: const [
                AppSpend(
                  packageName: 'gone',
                  label: 'Old App',
                  seconds: 600,
                  notInstalled: true,
                ),
              ],
            ),
          ),
        ),
      );
      final label = tester.widget<Text>(find.text('Old App'));
      final tokens = TallyTokens.of(TallyTheme.aurora, Brightness.dark);
      expect(label.style?.color, tokens.inkFaint);
    });

    testWidgets('a quiet day says so without congratulating', (tester) async {
      await tester.pumpWidget(wrap(BalanceScreen(model: balance())));
      expect(find.text('Nothing spent yet today.'), findsOneWidget);

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(texts, isNot(contains('!')));
      for (final word in ['great', 'well done', 'amazing', 'proud']) {
        expect(texts, isNot(contains(word)), reason: word);
      }
    });

    testWidgets('closes back to today', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        wrap(BalanceScreen(model: balance(), onClose: () => closed++)),
      );
      await tester.tap(find.bySemanticsLabel('Back to today'));
      expect(closed, 1);
    });
  });

  group('the pool sheet', () {
    testWidgets('lists what is waiting and adds a selection', (tester) async {
      List<String>? added;
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [task('Dentist'), task('Gym'), task('Dishes')],
              now: now,
              onAdd: (ids) => added = ids,
            ),
          ),
        ),
      );

      expect(find.text('3 waiting'), findsOneWidget);
      expect(find.text('Pick something to add'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Dentist'));
      await tester.pump();
      expect(find.text('Add 1 task'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Gym'));
      await tester.pump();
      expect(find.text('Add 2 tasks'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Add 2 tasks'));
      expect(added, hasLength(2));
    });

    testWidgets('the button will not fire with nothing picked', (tester) async {
      var adds = 0;
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [task('Dentist')],
              now: now,
              onAdd: (_) => adds++,
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Pick something to add'));
      expect(adds, 0);
    });

    testWidgets('tapping a picked task again unpicks it', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [task('Dentist')],
              now: now,
              onAdd: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Dentist'));
      await tester.pump();
      expect(find.text('Add 1 task'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Dentist'));
      await tester.pump();
      expect(find.text('Pick something to add'), findsOneWidget);
    });

    testWidgets('search narrows the list', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [task('Dentist'), task('Gym')],
              now: now,
              onAdd: (_) {},
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'gy');
      await tester.pump();
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Dentist'), findsNothing);
    });

    testWidgets('a search matching nothing says so', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [task('Dentist')],
              now: now,
              onAdd: (_) {},
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('Nothing matches that.'), findsOneWidget);
    });

    testWidgets('an empty pool explains where things come from',
        (tester) async {
      // Different from "nothing matched": there is nothing to match.
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(available: const [], now: now, onAdd: (_) {}),
          ),
        ),
      );
      expect(find.textContaining('Your list is empty'), findsOneWidget);
    });

    testWidgets('only stickers actually in use are offered as filters',
        (tester) async {
      // A filter row of all 24 base stickers would be mostly options that
      // return nothing.
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [
                task('Dishes', sticker: 'dishes'),
                task('Gym', sticker: 'gym'),
                task('Plain'),
              ],
              now: now,
              onAdd: (_) {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Filter by dishes'), findsOneWidget);
      expect(find.bySemanticsLabel('Filter by gym'), findsOneWidget);
      expect(find.bySemanticsLabel('Filter by music'), findsNothing);
    });

    testWidgets('a sticker filter narrows the list and toggles off',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [
                task('Dishes', sticker: 'dishes'),
                task('Gym', sticker: 'gym'),
              ],
              now: now,
              onAdd: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Filter by dishes'));
      await tester.pump();
      expect(find.text('Dishes'), findsOneWidget);
      expect(find.text('Gym'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Filter by dishes'));
      await tester.pump();
      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('a dread task carries how long it has been avoided',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: PoolSheet(
              available: [
                task(
                  'Clean the flat',
                  kind: TaskKind.dread,
                  created: DateTime.utc(2026, 7, 8),
                ),
              ],
              now: now,
              onAdd: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('avoided 34 days'), findsOneWidget);
    });
  });
}
