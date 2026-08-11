import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

final start = DateTime.utc(2026, 8, 11, 9);
DateTime at(int minutes, [int seconds = 0]) =>
    start.add(Duration(minutes: minutes, seconds: seconds));

FocusRun runOf({
  int minutes = 25,
  bool phoneDown = false,
  String? taskId = 'gym',
}) =>
    FocusRun(
      id: 'run-1',
      startedAt: start,
      planned: Duration(minutes: minutes),
      taskId: taskId,
      phoneDownRequested: phoneDown,
    );

void main() {
  group('wall clock, never ticks', () {
    test('elapsed comes from the clock, not from how often it was asked', () {
      // The whole point: the app can be backgrounded for twenty minutes and
      // deliver no ticks at all, and the block is still twenty minutes further
      // along when it comes back.
      final run = runOf();
      expect(run.elapsedSeconds(at(20)), 20 * 60);
      expect(run.remainingSeconds(at(20)), 5 * 60);
    });

    test('remaining never goes negative', () {
      final run = runOf(minutes: 5);
      expect(run.remainingSeconds(at(90)), 0);
      expect(run.isComplete(at(90)), isTrue);
    });

    test('completes exactly on the target, not a second early', () {
      final run = runOf(minutes: 25);
      expect(run.isComplete(at(24, 59)), isFalse);
      expect(run.isComplete(at(25)), isTrue);
    });
  });

  group('pausing', () {
    test('paused time does not count towards the block', () {
      final run = runOf().pause(at(10)).resume(at(15));
      // Ten minutes worked, five paused, so at the twenty minute mark only
      // fifteen have been focused.
      expect(run.elapsedSeconds(at(20)), 15 * 60);
      expect(run.remainingSeconds(at(20)), 10 * 60);
    });

    test('an open pause keeps the clock still', () {
      final run = runOf().pause(at(10));
      expect(run.elapsedSeconds(at(10)), 10 * 60);
      expect(run.elapsedSeconds(at(30)), 10 * 60, reason: 'still paused');
      expect(run.isPaused, isTrue);
    });

    test('pausing twice does nothing the second time', () {
      final run = runOf().pause(at(10)).pause(at(12));
      expect(run.pauses, hasLength(1));
      expect(run.elapsedSeconds(at(20)), 10 * 60);
    });

    test('resuming when not paused does nothing', () {
      final run = runOf().resume(at(10));
      expect(run.pauses, isEmpty);
      expect(run.elapsedSeconds(at(20)), 20 * 60);
    });

    test('several pauses all come off the total', () {
      final run = runOf(minutes: 60)
          .pause(at(5))
          .resume(at(10))
          .pause(at(20))
          .resume(at(25));
      expect(run.elapsedSeconds(at(30)), 20 * 60);
    });
  });

  group('extending', () {
    test('adds to the target without touching what was already worked', () {
      final run = runOf(minutes: 25).extend(const Duration(minutes: 10));
      expect(run.target, const Duration(minutes: 35));
      expect(run.elapsedSeconds(at(20)), 20 * 60);
      expect(run.remainingSeconds(at(20)), 15 * 60);
    });

    test('extending a finished block does nothing', () {
      final run = runOf().finish(at(25)).extend(const Duration(minutes: 10));
      expect(run.target, const Duration(minutes: 25));
    });
  });

  group('finishing', () {
    test('freezes the elapsed total', () {
      final run = runOf().finish(at(25));
      expect(run.elapsedSeconds(at(25)), 25 * 60);
      expect(run.elapsedSeconds(at(600)), 25 * 60, reason: 'already over');
      expect(run.isRunning, isFalse);
    });

    test('closes an open pause so the total stops moving', () {
      final run = runOf().pause(at(10)).finish(at(15));
      expect(run.elapsedSeconds(at(999)), 10 * 60);
      expect(run.isPaused, isFalse);
    });

    test('finishing twice keeps the first end', () {
      final run = runOf().finish(at(25)).finish(at(40));
      expect(run.elapsedSeconds(at(999)), 25 * 60);
    });
  });

  group('what the ledger receives', () {
    test('a running block produces nothing', () {
      expect(runOf().toSession(at(10)), isNull);
    });

    test('the session length is the focused time, not the wall span', () {
      // Ten minutes worked either side of a five minute pause. The session
      // handed to the engine is twenty minutes long, not twenty-five.
      final run = runOf(minutes: 25)
          .pause(at(10))
          .resume(at(15))
          .finish(at(30));
      final session = run.toSession(at(30))!;
      expect(session.seconds, 25 * 60);
      expect(session.endedAt, start.add(const Duration(minutes: 25)));
    });

    test('giving up early is a shorter session, not a failure', () {
      // Giving up costs nothing and breaks nothing, so it produces an ordinary
      // session and the engine applies its usual rules.
      final run = runOf(minutes: 25).finish(at(8));
      final session = run.toSession(at(8))!;
      expect(session.seconds, 8 * 60);
    });

    test('a block under the earning floor earns nothing, quietly', () {
      const settings = LedgerSettings();
      final run = runOf(minutes: 25).finish(at(3));
      final session = run.toSession(at(3))!;

      final result = LedgerEngine(offsetAt: fixedOffset(0)).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: at(60),
        sessions: [session],
      );
      expect(session.seconds, lessThan(settings.minEarnBlockSeconds));
      expect(result.days.single.earnedSeconds, 0);
    });

    test('a completed block earns its minutes through the real engine', () {
      final run = runOf(minutes: 25).finish(at(25));
      final result = LedgerEngine(offsetAt: fixedOffset(0)).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: at(60),
        sessions: [run.toSession(at(25))!],
      );
      expect((result.days.single.earnedSeconds / 60).round(), 25);
    });

    test('an empty block produces nothing rather than a zero session', () {
      final run = runOf().finish(start);
      expect(run.toSession(start), isNull);
    });
  });

  group('the phone-down bonus', () {
    test('is earned when the screen stayed off', () {
      final run = runOf(phoneDown: true).finish(at(20));
      expect(run.phoneDownEarned(at(20)), isTrue);
      expect(run.toSession(at(20))!.phoneDownVerified, isTrue);
    });

    test('a mid-block unlock costs the bonus and nothing else', () {
      // The block still counts at 1.0x with an honest note. The app declines
      // to pay extra rather than punishing.
      final run = runOf(phoneDown: true)
          .copyWith(screenUnlockedDuringBlock: true)
          .finish(at(20));
      expect(run.phoneDownEarned(at(20)), isFalse);
      final session = run.toSession(at(20))!;
      expect(session.phoneDownVerified, isFalse);
      expect(session.seconds, 20 * 60, reason: 'the time still counts');
    });

    test('an ordinary block never earns it, unlocked or not', () {
      final run = runOf().copyWith(screenUnlockedDuringBlock: false);
      expect(run.finish(at(20)).phoneDownEarned(at(20)), isFalse);
    });

    test('the bonus reaches the ledger as 1.5x', () {
      final run = runOf(minutes: 20, phoneDown: true).finish(at(20));
      final result = LedgerEngine(offsetAt: fixedOffset(0)).compute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: at(60),
        sessions: [run.toSession(at(20))!],
      );
      expect((result.days.single.earnedSeconds / 60).round(), 30);
    });
  });

  group('the countdown display', () {
    test('reads MM:SS under an hour', () {
      expect(FocusRun.format(0), '00:00');
      expect(FocusRun.format(59), '00:59');
      expect(FocusRun.format(60), '01:00');
      expect(FocusRun.format(25 * 60), '25:00');
      expect(FocusRun.format(1458), '24:18');
    });

    test('gains an hours field past an hour', () {
      expect(FocusRun.format(3600), '1:00:00');
      expect(FocusRun.format(7325), '2:02:05');
    });

    test('never shows a negative clock', () {
      expect(FocusRun.format(-30), '00:00');
    });
  });
}
