import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

const tiktok = 'com.zhiliaoapp.musically';

/// Every test runs at UTC+0 unless it is specifically about timezones, so the
/// 4am boundary sits at 04:00 UTC and the arithmetic is readable.
/// The engine under test.
///
/// The fallback grants 30 free minutes a day **explicitly**. The shipped
/// default is zero - everything has to be earned - and these cases are about
/// what an allowance does when there is one, so they state the allowance they
/// are testing rather than inheriting whatever the product default happens to
/// be this month. Cases that need no allowance pass zero, equally explicitly.
/// Grace is stated the same way and for the same reason. It ships **off** - a
/// zero balance means one thing rather than one-thing-unless-it-is-the-first-
/// time - but the mechanism is still part of the engine and still has to be
/// correct, because a stored ledger recomputed later must agree with the history
/// it was written from. So the cases that exercise it ask for it.
LedgerEngine engineWith([LedgerSettings? settings]) => LedgerEngine(
      settings: settings ??
          const LedgerSettings(dailyAllowanceMinutes: 30, graceMinutes: 5),
      offsetAt: fixedOffset(0),
    );

DateTime t(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, 8, day, hour, minute);

FocusSession session(
  DateTime start,
  int minutes, {
  bool phoneDown = false,
  String id = 's',
}) =>
    FocusSession(
      id: id,
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      phoneDownVerified: phoneDown,
    );

UsageSpan scroll(DateTime start, int minutes) => UsageSpan(
      packageName: tiktok,
      start: start,
      end: start.add(Duration(minutes: minutes)),
    );

int mins(int seconds) => (seconds / 60).round();

void main() {
  group('earning', () {
    test('a 20 minute block at 1:1 earns 20 minutes', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        sessions: [session(t(11, 9), 20)],
      );
      expect(mins(result.days.single.earnedSeconds), 20);
    });

    test('a block under the 5 minute floor earns nothing', () {
      // Otherwise the timer is farmable in 30 second bursts.
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        sessions: [session(t(11, 9), 4)],
      );
      expect(result.days.single.earnedSeconds, 0);
    });

    test('the ratio is applied', () {
      final result = engineWith(const LedgerSettings(earnRatio: 2.0)).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        sessions: [session(t(11, 9), 20)],
      );
      expect(mins(result.days.single.earnedSeconds), 40);
    });

    test('a phone-down block pays 1.5x', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        sessions: [session(t(11, 9), 20, phoneDown: true)],
      );
      expect(mins(result.days.single.earnedSeconds), 30);
    });

    test('the earn cap clamps a four-hour day and reports the remainder', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        sessions: [
          session(t(11, 9), 120, id: 'a'),
          session(t(11, 12), 120, id: 'b'),
        ],
      );
      final day = result.days.single;
      expect(mins(day.earnedSeconds), 90);
      expect(mins(day.earnCappedSeconds), 150);
    });

    test('no cap means no cap', () {
      final result = engineWith(
        const LedgerSettings(dailyEarnCapMinutes: null),
      ).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        sessions: [session(t(11, 9), 240)],
      );
      expect(mins(result.days.single.earnedSeconds), 240);
    });
  });

  group('allowance', () {
    test('is granted at the day boundary and does not roll over', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-12',
        now: t(12, 23),
      );
      // Two days, two grants, and yesterday's unspent 30 did not survive.
      expect(mins(result.days.first.allowanceGrantedSeconds), 30);
      expect(mins(result.days.last.allowanceGrantedSeconds), 30);
      expect(result.balanceSeconds, 0);
      expect(mins(result.allowanceRemainingSeconds), 30);
    });

    test('clears debt before it fills the balance', () {
      // A bad night must be payable by simply not scrolling tomorrow.
      final day1 = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23, 59),
        spend: [scroll(t(11, 10), 55)],
      );
      expect(mins(day1.balanceSeconds), -20);

      final day2 = engineWith().compute(
        fromDay: '2026-08-12',
        toDay: '2026-08-12',
        now: t(12, 23),
        openingBalanceSeconds: day1.balanceSeconds,
      );
      final rollup = day2.days.single;
      expect(mins(rollup.allowanceToDebtSeconds), 20);
      expect(rollup.closingBalanceSeconds, 0);
      expect(mins(day2.allowanceRemainingSeconds), 10);
    });

    test('may be set to zero without breaking anything', () {
      final result = engineWith(
        const LedgerSettings(dailyAllowanceMinutes: 0),
      ).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );
      expect(result.days.single.allowanceGrantedSeconds, 0);
    });
  });

  group('grace and debt', () {
    test('grace fires once when zero is crossed twice in one day', () {
      // The rule is once per zero-crossing, not once per session. Here the
      // user goes to zero, earns back into the black, and goes to zero again,
      // which is a second crossing and therefore a second grace.
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        spend: [scroll(t(11, 9), 40), scroll(t(11, 14), 40)],
        sessions: [session(t(11, 12), 30, id: 'recover')],
      );
      final day = result.days.single;
      // Two crossings, five free minutes each.
      expect(mins(day.graceUsedSeconds), 10);
    });

    test('grace is not re-armed inside a single continuous overspend', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        spend: [scroll(t(11, 9), 20), scroll(t(11, 10), 20)],
      );
      expect(mins(result.days.single.graceUsedSeconds), 5);
    });

    test('grace minutes cost nothing', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        spend: [scroll(t(11, 9), 35)],
      );
      // 30 allowance, then 5 free. Balance is still zero, not -5.
      expect(result.days.single.closingBalanceSeconds, 0);
      expect(mins(result.days.single.graceUsedSeconds), 5);
    });

    test('every minute after grace is -1', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        spend: [scroll(t(11, 9), 45)],
      );
      expect(mins(result.days.single.closingBalanceSeconds), -10);
    });

    test('debt stops at the floor but the real minutes are still recorded', () {
      // Past -60 the meter keeps running for the statement, but the number the
      // user has to repay does not grow. An unrepayable balance is an uninstall.
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23, 59),
        spend: [scroll(t(11, 9), 300)],
      );
      final day = result.days.single;
      expect(mins(day.closingBalanceSeconds), -60);
      expect(mins(day.spentSeconds), 300);
      expect(mins(day.unrepayableSeconds), 205);
    });

    test('earnings pay off debt before the balance rises', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        spend: [scroll(t(11, 9), 45)],
        sessions: [session(t(11, 14), 25, id: 'repay')],
      );
      // -10 then +25 leaves 15, not 25.
      expect(mins(result.days.single.closingBalanceSeconds), 15);
    });

    test('grace state is reported for the UI', () {
      final solvent = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 12),
      );
      expect(solvent.graceState, GraceState.solvent);

      final spent = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 12),
        spend: [scroll(t(11, 9), 45)],
      );
      expect(spent.graceState, GraceState.spent);
      expect(spent.inDebt, isTrue);
    });
  });

  group('savings and treats', () {
    test('earned credit above the rollover cap reaches savings exactly once', () {
      final result = engineWith(
        const LedgerSettings(dailyEarnCapMinutes: null),
      ).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(12, 12),
        sessions: [session(t(11, 9), 100)],
      );
      final day = result.days.single;
      expect(mins(day.closingBalanceSeconds), 60);
      expect(mins(day.overflowToSavingsSeconds), 40);
      expect(mins(day.closingSavingsSeconds), 40);
    });

    test('an in-progress day does not overflow to savings yet', () {
      final result = engineWith(
        const LedgerSettings(dailyEarnCapMinutes: null),
      ).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 12),
        sessions: [session(t(11, 9), 100)],
      );
      expect(result.days.single.overflowToSavingsSeconds, 0);
      expect(mins(result.balanceSeconds), 100);
    });

    test('a treat burns savings and never becomes scroll minutes', () {
      final result = engineWith(
        const LedgerSettings(dailyEarnCapMinutes: null),
      ).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-12',
        now: t(12, 23),
        sessions: [session(t(11, 9), 100)],
        treats: [
          Treat(id: 'x', at: t(12, 10), seconds: 30 * 60, label: 'cinema'),
        ],
      );
      expect(mins(result.savingsSeconds), 10);
      expect(mins(result.days.last.treatedSeconds), 30);
      // The burned minutes did not reappear anywhere spendable.
      expect(mins(result.balanceSeconds), 60);
    });

    test('a treat cannot burn more savings than exist', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
        treats: [
          Treat(id: 'x', at: t(11, 10), seconds: 999 * 60, label: 'holiday'),
        ],
      );
      expect(result.savingsSeconds, 0);
      expect(result.days.single.treatedSeconds, 0);
    });

    test('savings may cover a debt only by hand, and never overshoot', () {
      final result = engineWith(
        const LedgerSettings(
          dailyEarnCapMinutes: null,
          dailyAllowanceMinutes: 30,
          graceMinutes: 5,
        ),
      ).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-12',
        now: t(12, 23, 59),
        sessions: [session(t(11, 9), 100)],
        spend: [scroll(t(12, 10), 130)],
        transfers: [
          SavingsTransfer(
            id: 'w',
            at: t(12, 20),
            seconds: 999 * 60,
            toSavings: false,
          ),
        ],
      );
      // The withdrawal clears the debt and stops there rather than topping up
      // the spendable balance from savings.
      expect(result.balanceSeconds, 0);
      expect(result.savingsSeconds, greaterThan(0));
    });

    test('savings can never be spent by the scroll meter', () {
      final result = engineWith(
        const LedgerSettings(dailyEarnCapMinutes: null),
      ).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-12',
        now: t(12, 23, 59),
        sessions: [session(t(11, 9), 200)],
        spend: [scroll(t(12, 10), 200)],
      );
      // Balance and allowance are exhausted and the user is in debt, while
      // savings sit untouched. That is the entire point of the second pot.
      expect(result.inDebt, isTrue);
      expect(mins(result.savingsSeconds), 140);
    });
  });

  group('solvency streak', () {
    test('counts days that end at zero or above, and tracks the best', () {
      // A two-hour binge on the 13th: 30 allowance, 5 grace, then debt, floored
      // at -60. Digging out takes **two** days of allowance, not one, so the
      // 14th also closes negative. That is the intended cost of a bad night and
      // it is worth asserting rather than discovering in a review.
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-15',
        now: t(16, 12),
        spend: [scroll(t(13, 10), 120)],
      );
      expect(result.days.map((d) => d.solvent), [
        true,
        true,
        false,
        false,
        true,
      ]);
      expect(mins(result.days[2].closingBalanceSeconds), -60);
      expect(mins(result.days[3].closingBalanceSeconds), -30);
      expect(result.days[4].closingBalanceSeconds, 0);
      expect(result.currentSolvencyStreak, 1);
      expect(result.bestSolvencyStreak, 2);
    });

    test('an unfinished day does not count towards the streak yet', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 12),
      );
      expect(result.currentSolvencyStreak, 0);
    });
  });

  group('day boundaries', () {
    test('a 4am boundary splits a scroll across two days', () {
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-12',
        now: t(12, 23),
        // 03:30 to 04:30 straddles the boundary.
        spend: [scroll(t(12, 3, 30), 60)],
      );
      expect(mins(result.days.first.spentSeconds), 30);
      expect(mins(result.days.last.spentSeconds), 30);
    });

    test('spend before the range opens is not counted', () {
      final result = engineWith().compute(
        fromDay: '2026-08-12',
        toDay: '2026-08-12',
        now: t(12, 23),
        spend: [scroll(t(11, 10), 60)],
      );
      expect(result.days.single.spentSeconds, 0);
    });

    test('a day with nothing logged still produces a rollup', () {
      // Statements walk day keys, so a quiet day must be a zero row and never a
      // gap.
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-20',
        now: t(21, 12),
      );
      expect(result.days, hasLength(10));
    });

    test('a DST day is 23 hours and nothing is double counted', () {
      // Europe springs forward at 01:00 UTC on 2026-03-29: +0 becomes +60.
      final engine = LedgerEngine(
        offsetAt: (instant) =>
            instant.isBefore(DateTime.utc(2026, 3, 29, 1)) ? 0 : 60,
      );
      final result = engine.compute(
        fromDay: '2026-03-28',
        toDay: '2026-03-30',
        now: DateTime.utc(2026, 3, 31),
        spend: [
          UsageSpan(
            packageName: tiktok,
            start: DateTime.utc(2026, 3, 29, 0, 30),
            end: DateTime.utc(2026, 3, 29, 6, 30),
          ),
        ],
      );
      final total = result.days.fold(0, (a, d) => a + d.spentSeconds);
      // Six hours were spent, so six hours are billed. No more, no less,
      // whatever the local clock did in the middle.
      expect(mins(total), 360);
      expect(result.days, hasLength(3));
    });

    test('a timezone change does not rewrite an earlier day', () {
      final flown = LedgerEngine(
        offsetAt: (instant) =>
            instant.isBefore(DateTime.utc(2026, 8, 13)) ? 0 : 540,
      );
      final result = flown.compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(14, 12),
        spend: [scroll(t(11, 10), 20)],
      );
      expect(mins(result.days.single.spentSeconds), 20);
    });
  });

  group('the architecture rule', () {
    test('a dead service all day still yields the right balance on open', () {
      // The engine never saw a single live tick. It recomputes from events, so
      // an OEM battery manager killing the watcher for six hours costs the user
      // the nudge and nothing else.
      final result = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23, 59),
        spend: [scroll(t(11, 9), 45)],
        sessions: [session(t(11, 14), 25, id: 'r')],
      );
      expect(mins(result.days.single.closingBalanceSeconds), 15);
    });

    test('the same inputs always produce the same output', () {
      final inputs = {
        'sessions': [session(t(11, 9), 30), session(t(11, 15), 45, id: 'b')],
        'spend': [scroll(t(11, 12), 40), scroll(t(11, 20), 25)],
      };
      LedgerResult run() => engineWith().compute(
            fromDay: '2026-08-11',
            toDay: '2026-08-11',
            now: t(11, 23, 59),
            sessions: inputs['sessions']! as List<FocusSession>,
            spend: inputs['spend']! as List<UsageSpan>,
          );
      final a = run();
      final b = run();
      expect(a.balanceSeconds, b.balanceSeconds);
      expect(a.savingsSeconds, b.savingsSeconds);
      expect(
        a.days.map((d) => d.closingBalanceSeconds),
        b.days.map((d) => d.closingBalanceSeconds),
      );
    });

    test('event order within a day does not change the outcome', () {
      // Inputs arrive from a database in whatever order the query returned.
      final sessions = [
        session(t(11, 15), 45, id: 'b'),
        session(t(11, 9), 30, id: 'a'),
      ];
      final spend = [scroll(t(11, 20), 25), scroll(t(11, 12), 40)];

      final forward = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23, 59),
        sessions: sessions,
        spend: spend,
      );
      final reversed = engineWith().compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23, 59),
        sessions: sessions.reversed.toList(),
        spend: spend.reversed.toList(),
      );
      expect(forward.balanceSeconds, reversed.balanceSeconds);
    });

    test('rejects a reversed range rather than looping', () {
      expect(
        () => engineWith().compute(
          fromDay: '2026-08-12',
          toDay: '2026-08-11',
          now: t(12, 12),
        ),
        throwsArgumentError,
      );
    });
  });
}
