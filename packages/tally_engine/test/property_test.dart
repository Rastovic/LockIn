import 'dart:math';

import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

const tiktok = 'com.zhiliaoapp.musically';

/// A randomised but reproducible month of use.
///
/// Seeded so a failure can be replayed exactly. An unseeded property test that
/// fails once and never again is worse than no property test.
({List<FocusSession> sessions, List<UsageSpan> spend, List<Treat> treats})
    randomMonth(int seed) {
  final rng = Random(seed);
  final sessions = <FocusSession>[];
  final spend = <UsageSpan>[];
  final treats = <Treat>[];

  for (var day = 1; day <= 28; day++) {
    for (var i = 0; i < rng.nextInt(4); i++) {
      final start = DateTime.utc(2026, 6, day, 6 + rng.nextInt(14), rng.nextInt(60));
      sessions.add(
        FocusSession(
          id: 's$day-$i',
          startedAt: start,
          // Deliberately includes blocks under the 5 minute earning floor.
          endedAt: start.add(Duration(minutes: 1 + rng.nextInt(90))),
          phoneDownVerified: rng.nextBool(),
        ),
      );
    }
    for (var i = 0; i < rng.nextInt(6); i++) {
      // Starts anywhere in the 24h clock, so some spans straddle the 4am
      // boundary and land in two days.
      final start = DateTime.utc(2026, 6, day, rng.nextInt(24), rng.nextInt(60));
      spend.add(
        UsageSpan(
          packageName: tiktok,
          start: start,
          end: start.add(Duration(minutes: 1 + rng.nextInt(120))),
        ),
      );
    }
    if (rng.nextInt(10) == 0) {
      treats.add(
        Treat(
          id: 't$day',
          at: DateTime.utc(2026, 6, day, 19),
          seconds: (5 + rng.nextInt(120)) * 60,
          label: 'treat',
        ),
      );
    }
  }
  return (sessions: sessions, spend: spend, treats: treats);
}

LedgerResult run(int seed, {List<UsageSpan>? spendOverride}) {
  final month = randomMonth(seed);
  return LedgerEngine(offsetAt: fixedOffset(0)).compute(
    fromDay: '2026-06-01',
    toDay: '2026-06-28',
    now: DateTime.utc(2026, 7, 1),
    sessions: month.sessions,
    spend: mergeOverlapping(spendOverride ?? month.spend),
    treats: month.treats,
  );
}

void main() {
  group('property: the engine is a pure function', () {
    test('the same random stream twice gives identical output', () {
      for (var seed = 0; seed < 40; seed++) {
        final a = run(seed);
        final b = run(seed);
        expect(a.balanceSeconds, b.balanceSeconds, reason: 'seed $seed');
        expect(a.savingsSeconds, b.savingsSeconds, reason: 'seed $seed');
        expect(a.bestSolvencyStreak, b.bestSolvencyStreak, reason: 'seed $seed');
        expect(
          a.days.map((d) => d.closingBalanceSeconds).toList(),
          b.days.map((d) => d.closingBalanceSeconds).toList(),
          reason: 'seed $seed',
        );
      }
    });

    test('shuffling the input order changes nothing', () {
      for (var seed = 0; seed < 40; seed++) {
        final month = randomMonth(seed);
        final engine = LedgerEngine(offsetAt: fixedOffset(0));
        LedgerResult compute(List<UsageSpan> spend, List<FocusSession> ses) =>
            engine.compute(
              fromDay: '2026-06-01',
              toDay: '2026-06-28',
              now: DateTime.utc(2026, 7, 1),
              sessions: ses,
              spend: mergeOverlapping(spend),
              treats: month.treats,
            );

        final ordered = compute(month.spend, month.sessions);
        final shuffled = compute(
          [...month.spend]..shuffle(Random(seed + 1000)),
          [...month.sessions]..shuffle(Random(seed + 2000)),
        );
        expect(
          ordered.balanceSeconds,
          shuffled.balanceSeconds,
          reason: 'seed $seed',
        );
      }
    });
  });

  group('property: invariants that must hold for any input', () {
    test('the repayable balance never falls below the debt floor', () {
      for (var seed = 0; seed < 40; seed++) {
        final result = run(seed);
        for (final day in result.days) {
          expect(
            day.closingBalanceSeconds,
            greaterThanOrEqualTo(-60 * 60),
            reason: 'seed $seed on ${day.dayKey}',
          );
        }
      }
    });

    test('savings are never negative', () {
      for (var seed = 0; seed < 40; seed++) {
        final result = run(seed);
        expect(result.savingsSeconds, greaterThanOrEqualTo(0));
        for (final day in result.days) {
          expect(day.closingSavingsSeconds, greaterThanOrEqualTo(0));
        }
      }
    });

    test('a day never earns more than the cap', () {
      for (var seed = 0; seed < 40; seed++) {
        for (final day in run(seed).days) {
          expect(day.earnedSeconds, lessThanOrEqualTo(90 * 60));
        }
      }
    });

    test('grace never exceeds its allowance per day', () {
      // Several crossings a day are possible, so this is not a flat 5 minutes,
      // but it can never be negative and never exceed the day's spend.
      for (var seed = 0; seed < 40; seed++) {
        for (final day in run(seed).days) {
          expect(day.graceUsedSeconds, greaterThanOrEqualTo(0));
          expect(day.graceUsedSeconds, lessThanOrEqualTo(day.spentSeconds));
        }
      }
    });

    test('no day reports negative earnings or spend', () {
      for (var seed = 0; seed < 40; seed++) {
        for (final day in run(seed).days) {
          expect(day.earnedSeconds, greaterThanOrEqualTo(0));
          expect(day.spentSeconds, greaterThanOrEqualTo(0));
          expect(day.unrepayableSeconds, greaterThanOrEqualTo(0));
        }
      }
    });

    test('adding a treat can never increase spendable minutes', () {
      // The loophole that would turn savings into a laundering route back into
      // scroll time. It must be closed under every input, not just the obvious
      // one.
      for (var seed = 0; seed < 40; seed++) {
        final month = randomMonth(seed);
        final engine = LedgerEngine(offsetAt: fixedOffset(0));
        LedgerResult compute(List<Treat> treats) => engine.compute(
              fromDay: '2026-06-01',
              toDay: '2026-06-28',
              now: DateTime.utc(2026, 7, 1),
              sessions: month.sessions,
              spend: mergeOverlapping(month.spend),
              treats: treats,
            );

        final without = compute(const []);
        final with_ = compute([
          ...month.treats,
          Treat(
            id: 'extra',
            at: DateTime.utc(2026, 6, 15, 20),
            seconds: 45 * 60,
            label: 'lunch',
          ),
        ]);
        expect(
          with_.spendableSeconds,
          lessThanOrEqualTo(without.spendableSeconds),
          reason: 'seed $seed',
        );
      }
    });

    test('every day in the range is present exactly once, in order', () {
      for (var seed = 0; seed < 10; seed++) {
        final days = run(seed).days.map((d) => d.dayKey).toList();
        expect(days, hasLength(28));
        expect(days.toSet(), hasLength(28));
        expect(days, orderedEquals([...days]..sort()));
      }
    });

    test('total spend equals the merged input, never more', () {
      // The double-counting guard, stated as an accounting identity.
      for (var seed = 0; seed < 40; seed++) {
        final month = randomMonth(seed);
        final merged = mergeOverlapping(month.spend);
        final engine = LedgerEngine(offsetAt: fixedOffset(0));
        final result = engine.compute(
          fromDay: '2026-06-01',
          toDay: '2026-06-30',
          now: DateTime.utc(2026, 7, 5),
          spend: merged,
        );
        final billed = result.days.fold(0, (a, d) => a + d.spentSeconds);
        // Offered is the merged input clamped to the same window the engine
        // walked. A span that starts before the range and runs into it is
        // partly billable, so comparing whole spans would understate it.
        final windowStart = engine.dayStart('2026-06-01');
        final windowEnd = engine.dayStart('2026-07-01');
        final offered = merged.fold(
          0,
          (a, s) => a + (s.clampTo(windowStart, windowEnd)?.seconds ?? 0),
        );
        // Equality, not just an upper bound: every offered second inside the
        // window is billed exactly once. That is the double-counting guard and
        // the dropped-minutes guard in one assertion.
        expect(billed, offered, reason: 'seed $seed');
      }
    });
  });
}
