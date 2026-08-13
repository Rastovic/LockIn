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
    // silently dropping it would be a broken app.
    expect(alarm.kind, NudgeKind.scheduled);
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
