import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

/// The surface the UI reads. Small, but the Balance screen renders straight
/// from it, so a sign error here is a wrong number in the user's face.
void main() {
  LedgerResult resultWith({
    required int balance,
    int allowance = 0,
    int savings = 0,
  }) =>
      LedgerResult(
        balanceSeconds: balance,
        allowanceRemainingSeconds: allowance,
        savingsSeconds: savings,
        graceState: GraceState.solvent,
        graceRemainingSeconds: 0,
        currentSolvencyStreak: 0,
        bestSolvencyStreak: 0,
        days: const [],
      );

  group('spendable', () {
    test('adds unspent allowance to a positive balance', () {
      // The user sees one number. Allowance and earned credit are separate
      // internally only because one expires and the other rolls over.
      final r = resultWith(balance: 20 * 60, allowance: 10 * 60);
      expect(r.spendableMinutes, 30);
      expect(r.inDebt, isFalse);
    });

    test('in debt, allowance is already spent so the debt stands alone', () {
      final r = resultWith(balance: -15 * 60);
      expect(r.spendableMinutes, -15);
      expect(r.inDebt, isTrue);
    });

    test('zero is solvent, not debt', () {
      expect(resultWith(balance: 0).inDebt, isFalse);
    });

    test('minutes floor towards negative infinity, never towards zero', () {
      // 90 seconds of debt is -2 minutes shown, not -1. Rounding a debt
      // towards zero would flatter the number, which is the one thing this app
      // must never do.
      expect(resultWith(balance: -90).spendableMinutes, -2);
      expect(resultWith(balance: 90).spendableMinutes, 1);
    });
  });

  group('DayRollup', () {
    test('net is earned minus spent and may be negative', () {
      const day = DayRollup(
        dayKey: '2026-08-11',
        allowanceGrantedSeconds: 1800,
        allowanceToDebtSeconds: 0,
        earnedSeconds: 1200,
        earnCappedSeconds: 0,
        spentSeconds: 3000,
        graceUsedSeconds: 300,
        unrepayableSeconds: 0,
        closingBalanceSeconds: -600,
        closingSavingsSeconds: 0,
        overflowToSavingsSeconds: 0,
        treatedSeconds: 0,
        solvent: false,
      );
      expect(day.netSeconds, -1800);
      expect(day.toString(), contains('2026-08-11'));
    });
  });

  group('LedgerSettings', () {
    test('converts minutes to seconds', () {
      const s = LedgerSettings();
      expect(s.dailyAllowanceSeconds, 1800);
      expect(s.rolloverCapSeconds, 3600);
      expect(s.graceSeconds, 300);
      expect(s.minEarnBlockSeconds, 300);
      expect(s.dailyEarnCapSeconds, 5400);
    });

    test('the debt floor is stored positive and read negative', () {
      // Stored as a magnitude so the settings screen never shows a minus sign
      // on a field the user is raising.
      expect(const LedgerSettings().debtFloorSeconds, -3600);
    });

    test('copyWith changes one field and keeps the rest', () {
      final s = const LedgerSettings().copyWith(earnRatio: 2.0);
      expect(s.earnRatio, 2.0);
      expect(s.dailyAllowanceMinutes, 30);
    });

    test('the earn cap can be cleared, which copyWith alone cannot express', () {
      final s = const LedgerSettings().copyWith(clearEarnCap: true);
      expect(s.dailyEarnCapMinutes, isNull);
      expect(s.dailyEarnCapSeconds, isNull);
    });

    test('rejects settings that would break the ledger', () {
      expect(() => LedgerSettings(earnRatio: 0), throwsA(isA<AssertionError>()));
      expect(
        () => LedgerSettings(phoneDownMultiplier: 0.5),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => LedgerSettings(debtFloorMinutes: -60),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('FocusSession', () {
    test('reports its own length', () {
      final s = FocusSession(
        id: 'a',
        startedAt: DateTime.utc(2026, 8, 11, 9),
        endedAt: DateTime.utc(2026, 8, 11, 9, 25),
      );
      expect(s.seconds, 1500);
      expect(s.toString(), contains('1500s'));
    });

    test('refuses to end before it starts', () {
      expect(
        () => FocusSession(
          id: 'a',
          startedAt: DateTime.utc(2026, 8, 11, 9),
          endedAt: DateTime.utc(2026, 8, 11, 8),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
