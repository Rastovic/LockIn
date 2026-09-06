import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally_data/tally_data.dart';
import 'package:vitals_notify/vitals_notify.dart';

/// The end-of-block alarm.
///
/// A focus block is most useful when the phone is being used for the thing
/// being focused on - studying on the same phone means leaving this app, and a
/// countdown nobody is looking at is not a timer.
const install = '018f2c00-aaaa-7000-8000-000000000001';

/// The id the controller uses for the end-of-block alarm.
const _focusAlarmId = 8801;

TallyController build(RecordingNotifier notifier, {DateTime? at}) {
  var now = at ?? DateTime.utc(2026, 8, 13, 10);
  return TallyController(
    db: TallyDatabase(NativeDatabase.memory()),
    installId: install,
    notifier: notifier,
    clock: () => now,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a block that expired while the app was closed still opens the app',
      () async {
    // The process died during a block and the app is only being reopened now,
    // long after the clock ran out. Restoring it used to arm an alarm for an
    // instant that had gone: the scheduler rejects a past date, the throw
    // escaped `load`, and `loading` stayed true - which renders nothing at
    // all. The app opened to a blank screen with no route out.
    final now = DateTime.utc(2026, 8, 13, 10);
    SharedPreferences.setMockInitialValues({
      'tally.focus': jsonEncode({
        'id': '018f2c00-bbbb-7000-8000-000000000002',
        'startedAt':
            now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'plannedSeconds': 45 * 60,
        'extendedSeconds': 0,
        'taskId': null,
        'phoneDown': false,
        'unlocked': false,
        'pauses': <Object>[],
      }),
    });

    // The real plugin throws on a past date. RecordingNotifier does not, so a
    // test using it would pass whether or not the bug is present.
    final notifier = _RejectsPastDates();
    final c = build(notifier, at: now);
    await c.load();

    expect(c.loading, isFalse, reason: 'the app must reach a drawable state');
    expect(
      notifier.scheduled,
      isEmpty,
      reason: 'there is nothing left to ring for',
    );
  });

  test('opening the app on a just-rung alarm does not wipe the notice',
      () async {
    // The alarm rings, the user picks the phone up and opens the app - which
    // is the whole point of the ring. `cancel` takes a *shown* notification
    // down as well as a pending alarm, so reconciling on open used to erase
    // the ring a moment after it arrived, and the block read as unfinished.
    final now = DateTime.utc(2026, 8, 13, 10);
    SharedPreferences.setMockInitialValues({
      'tally.focus': jsonEncode({
        'id': '018f2c00-dddd-7000-8000-000000000004',
        'startedAt':
            now.subtract(const Duration(minutes: 45)).millisecondsSinceEpoch,
        'plannedSeconds': 45 * 60,
        'extendedSeconds': 0,
        'taskId': null,
        'phoneDown': false,
        'unlocked': false,
        'pauses': <Object>[],
      }),
    });

    final notifier = _RejectsPastDates();
    final c = build(notifier, at: now);
    await c.load();

    expect(
      notifier.cancelled,
      isNot(contains(_focusAlarmId)),
      reason: 'the ring the user just answered must stay on screen',
    );
  });

  group('exact alarms', () {
    test('a block notices when Android will not deliver on time', () async {
      // Off by default from Android 14 for an app targeting a recent SDK, so
      // this is the state of every fresh install until someone grants it.
      // Left undetected it produces the worst kind of bug report: the timer
      // works, sometimes, and is minutes late the rest of the time.
      final notifier = RecordingNotifier()..exactScheduling = false;
      final c = build(notifier);

      c.startFocus(minutes: 45);
      await Future<void>.delayed(Duration.zero);

      expect(c.focusAlarmImprecise, isTrue);
      expect(
        notifier.scheduled,
        hasLength(1),
        reason: 'it still rings, just not punctually',
      );
    });

    test('granted, nothing is said', () async {
      final c = build(RecordingNotifier());
      c.startFocus(minutes: 45);
      await Future<void>.delayed(Duration.zero);

      expect(c.focusAlarmImprecise, isFalse);
    });

    test('asking re-arms the running block', () async {
      // The alarm already registered for this block went in as inexact and
      // does not change retroactively. Without the reschedule, granting the
      // permission would fix every future block except the one the user is
      // sitting in front of.
      final notifier = RecordingNotifier()..exactScheduling = false;
      final c = build(notifier);

      c.startFocus(minutes: 45);
      await Future<void>.delayed(Duration.zero);
      notifier.exactScheduling = true;

      await c.requestExactAlarms();

      expect(notifier.exactRequests, 1);
      expect(c.focusAlarmImprecise, isFalse);
      expect(notifier.cancelled, contains(_focusAlarmId));
      expect(notifier.scheduled, hasLength(1));
    });
  });

  test('completing a block leaves its alarm alone', () async {
    // The alarm is due at the instant the block completes, and the countdown
    // keeps ticking while the app sits in the background - so this method is
    // reached at that same instant, milliseconds before the OS delivers the
    // alarm. Cancelling here killed the ring, and only when the process
    // happened to still be alive: the timer worked after Android had killed
    // the app and failed when it had not.
    final notifier = RecordingNotifier();
    final c = build(notifier);

    c.startFocus(minutes: 45);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.scheduled, hasLength(1));

    await c.endFocus(at: DateTime.utc(2026, 8, 13, 10, 45));

    expect(
      notifier.scheduled,
      hasLength(1),
      reason: 'the ring the user is waiting for must survive',
    );
  });

  test('giving up cancels the alarm', () async {
    final notifier = RecordingNotifier();
    final c = build(notifier);

    c.startFocus(minutes: 45);
    await Future<void>.delayed(Duration.zero);

    // Ended early, so nothing finished and nothing should ring.
    await c.endFocus(at: DateTime.utc(2026, 8, 13, 10, 20));

    expect(notifier.scheduled, isEmpty);
  });

  test('starting a block schedules an alarm for its end', () async {
    final notifier = RecordingNotifier();
    final c = build(notifier);

    c.startFocus(minutes: 45);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.scheduled, hasLength(1));
    final alarm = notifier.scheduled.single;
    expect(alarm.at, DateTime.utc(2026, 8, 13, 10, 45));
    expect(alarm.body, contains('45 minute'));
    // Never capped and never held back: the user started this timer, and
    // silently dropping it would be a broken app. An alarm rather than a
    // plain scheduled notice, so it rings on the alarm stream - a block ends
    // with the phone face down, where a notification chime is missed.
    expect(alarm.kind, NudgeKind.alarm);
    expect(alarm.quietHoursExempt, isTrue);
  });

  test('pausing cancels it and resuming sets a new one', () async {
    final notifier = RecordingNotifier();
    final c = build(notifier);

    c.startFocus(minutes: 25);
    await Future<void>.delayed(Duration.zero);
    c.pauseFocus();
    await Future<void>.delayed(Duration.zero);
    // A paused block has no end to aim at.
    expect(notifier.scheduled, isEmpty);

    c.resumeFocus();
    await Future<void>.delayed(Duration.zero);
    expect(notifier.scheduled, hasLength(1));
  });

  test('extending moves the alarm rather than adding one', () async {
    final notifier = RecordingNotifier();
    final c = build(notifier);

    c.startFocus(minutes: 25);
    await Future<void>.delayed(Duration.zero);
    c.extendFocus(const Duration(minutes: 10));
    await Future<void>.delayed(Duration.zero);

    expect(notifier.scheduled, hasLength(1), reason: 'one block, one alarm');
    expect(notifier.scheduled.single.at, DateTime.utc(2026, 8, 13, 10, 35));
  });

  test('ending a block leaves nothing scheduled', () async {
    final notifier = RecordingNotifier();
    final c = build(notifier);

    c.startFocus(minutes: 25);
    await Future<void>.delayed(Duration.zero);
    await c.endFocus();

    expect(notifier.scheduled, isEmpty);
  });

  test('denied notifications are reported, not swallowed', () async {
    // The alarm exists because people leave this screen during a block. If it
    // cannot ring, that has to be said before the block, not discovered by
    // missing the end of one.
    final notifier = RecordingNotifier()
      ..permissionState = NotificationPermission.denied;
    final c = build(notifier);

    c.startFocus(minutes: 25);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.scheduled, isEmpty);
    expect(c.focusAlarmBlocked, isTrue);
  });
}

/// A notifier that fails the way the real plugin fails.
///
/// `flutter_local_notifications` throws `ArgumentError` when asked to schedule
/// anything that is not in the future. [RecordingNotifier] accepts it happily,
/// so a test built on that double cannot see the difference between an alarm
/// that was armed correctly and one that would have brought the app down.
final class _RejectsPastDates extends RecordingNotifier {
  @override
  Future<void> schedule(Nudge nudge) async {
    if (!nudge.at.isAfter(DateTime.utc(2026, 8, 13, 10))) {
      throw ArgumentError.value(
        nudge.at,
        'scheduledDate',
        'Must be a date in the future',
      );
    }
    await super.schedule(nudge);
  }
}
