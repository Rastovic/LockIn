import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_ui/tally_ui.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.blush, Brightness.light),
      home: child,
    );

/// The first day of real use produced a balance of −2, a spend of 66 on one
/// screen and 67 on another, and nothing anywhere saying how they related.
void main() {
  group('how this adds up', () {
    testWidgets('shows the terms that produced the balance', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceScreen(
            model: const BalanceScreenModel(
              spendableSeconds: -120,
              earnedSeconds: 0,
              spentSeconds: 4020,
              savingsSeconds: 0,
              solvencyStreak: 0,
              bestStreak: 0,
              allowanceSeconds: 3600,
              graceUsedSeconds: 300,
            ),
          ),
        ),
      );

      expect(find.text('HOW THIS ADDS UP'), findsOneWidget);
      expect(find.text('+60'), findsOneWidget); // allowance
      expect(find.text('+5'), findsOneWidget); // grace
      expect(find.text('−67'), findsOneWidget); // spent, signed
      expect(find.text('−2'), findsWidgets); // the balance itself
    });

    testWidgets('defines borrowing where the negative number is', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          BalanceScreen(
            model: const BalanceScreenModel(
              spendableSeconds: -120,
              earnedSeconds: 0,
              spentSeconds: 4020,
              savingsSeconds: 0,
              solvencyStreak: 0,
              bestStreak: 0,
              allowanceSeconds: 3600,
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Below zero is borrowing'),
        findsOneWidget,
      );
    });

    testWidgets('stays hidden when there is nothing to add up', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceScreen(
            model: const BalanceScreenModel(
              spendableSeconds: 1800,
              earnedSeconds: 0,
              spentSeconds: 0,
              savingsSeconds: 0,
              solvencyStreak: 0,
              bestStreak: 0,
              allowanceSeconds: 1800,
            ),
          ),
        ),
      );
      // One term is not a sum. A box showing "allowance 30, balance 30" is
      // noise on a day where nothing has happened yet.
      expect(find.text('HOW THIS ADDS UP'), findsNothing);
    });
  });

  group('where it went', () {
    final model = BalanceScreenModel(
      spendableSeconds: -120,
      earnedSeconds: 0,
      spentSeconds: 4020,
      savingsSeconds: 0,
      solvencyStreak: 0,
      bestStreak: 0,
      allowanceSeconds: 3600,
      spendByApp: [
        AppSpend(
          packageName: 'com.tiktok',
          label: 'TikTok',
          seconds: 4020,
          sessions: [
            // Local, not UTC: the screen renders in local time, and a test
            // built on UTC instants would pass or fail depending on the
            // timezone of the machine running it.
            AppSession(
              startedAt: DateTime(2026, 8, 11, 12, 5),
              endedAt: DateTime(2026, 8, 11, 12, 47),
            ),
            AppSession(
              startedAt: DateTime(2026, 8, 11, 21, 30),
              endedAt: DateTime(2026, 8, 11, 21, 54),
            ),
          ],
        ),
      ],
    );

    testWidgets('an app opens to the times behind its total', (tester) async {
      await tester.pumpWidget(wrap(BalanceScreen(model: model)));

      // Collapsed by default: the total is the headline, the audit is on ask.
      expect(find.text('12:05 to 12:47'), findsNothing);

      await tester.ensureVisible(find.text('TikTok'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TikTok'));
      await tester.pump();

      // The stretches are what make the total checkable against a memory of
      // the day, which is the whole reason they are here.
      expect(find.text('12:05 to 12:47'), findsOneWidget);
      expect(find.text('21:30 to 21:54'), findsOneWidget);
      expect(find.text('42m'), findsOneWidget);
      expect(find.text('24m'), findsOneWidget);
    });
  });

  /// The day that produced the report: 97m40s spent against a −55 carry-in,
  /// which is past the debt floor. Two numbers were wrong on one screen - the
  /// spend read −98 in the sum and 97 in the tile below it, and the column did
  /// not add up to the total because the floor was not one of its terms.
  group('a day that hit the debt floor', () {
    const model = BalanceScreenModel(
      spendableSeconds: -3600,
      earnedSeconds: 0,
      spentSeconds: 5860,
      savingsSeconds: 0,
      solvencyStreak: 0,
      bestStreak: 0,
      openingSeconds: -3300,
      allowanceSeconds: 3600,
      unrepayableSeconds: 1960,
    );

    testWidgets('spend reads the same as the tile below it', (tester) async {
      await tester.pumpWidget(wrap(const BalanceScreen(model: model)));

      // Floor the magnitude, then sign it: −98 here beside 97 there is the
      // same seconds disagreeing with itself.
      expect(find.text('−97'), findsOneWidget);
      expect(find.text('−98'), findsNothing);
      expect(find.text('97'), findsOneWidget); // the SPENT tile
    });

    testWidgets('the terms add up to the total', (tester) async {
      await tester.pumpWidget(wrap(const BalanceScreen(model: model)));

      expect(find.text('−55'), findsOneWidget); // carried in
      expect(find.text('+60'), findsOneWidget); // allowance
      expect(find.text('+32'), findsOneWidget); // not charged, past the floor
      // −55 + 60 − 97 + 32 = −60, and the total says so.
      expect(find.text('−60'), findsWidgets);
      expect(find.text('Rounding'), findsNothing);
    });
  });
}
