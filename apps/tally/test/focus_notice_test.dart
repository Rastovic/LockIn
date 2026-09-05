import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally/platform/android_focus_notice.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// The countdown outside the app.
///
/// What crosses the channel is an **absolute end instant**, not a duration.
/// That is the whole design: Android ticks the digits from it, so the countdown
/// keeps falling while this app's process is dead - which is the normal state
/// during a block, since the point is to put the phone down.
const install = '018f2c00-aaaa-7000-8000-000000000001';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tally/usage');

  late List<MethodCall> calls;
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    now = DateTime.utc(2026, 8, 17, 10);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'drainCaptures') return <String>[];
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  TallyController open(TallyDatabase db) => TallyController(
        db: db,
        installId: install,
        focusNotice: const AndroidFocusNotice(),
        clock: () => now,
      );

  MethodCall? lastNotice() =>
      calls.where((c) => c.method == 'showFocusNotice').lastOrNull;

  Future<(TallyController, Task)> withPlannedTask() async {
    final c = open(TallyDatabase(NativeDatabase.memory()));
    await c.load();
    final task = await c.createTask(
      const TaskDraft(
        kind: TaskKind.oneoff,
        title: 'Write the intro',
        estimateMinutes: 25,
      ),
    );
    await c.addToToday([task.id]);
    return (c, task);
  }

  test('starting a block posts a countdown that ends when the block does',
      () async {
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    await Future<void>.delayed(Duration.zero);

    final notice = lastNotice();
    expect(notice, isNotNull);
    final args = notice!.arguments as Map<Object?, Object?>;
    expect(
      args['endsAtMillis'],
      now.add(const Duration(minutes: 25)).millisecondsSinceEpoch,
    );
    expect(args['remainingSeconds'], 25 * 60);
    expect(args['totalSeconds'], 25 * 60);
    expect(args['paused'], isFalse);
    // Named, so the shade says what is being worked on rather than "Focusing".
    expect(args['taskTitle'], 'Write the intro');
  });

  test('extending moves the end it counts towards', () async {
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    c.extendFocus(const Duration(minutes: 10));
    await Future<void>.delayed(Duration.zero);

    final args = lastNotice()!.arguments as Map<Object?, Object?>;
    expect(
      args['endsAtMillis'],
      now.add(const Duration(minutes: 35)).millisecondsSinceEpoch,
    );
    expect(args['totalSeconds'], 35 * 60);
  });

  test('pausing says so instead of counting towards a time that is not coming',
      () async {
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    now = now.add(const Duration(minutes: 5));
    c.pauseFocus();
    await Future<void>.delayed(Duration.zero);

    final args = lastNotice()!.arguments as Map<Object?, Object?>;
    expect(args['paused'], isTrue);
    expect(args['remainingSeconds'], 20 * 60);
  });

  test('resuming counts towards the new end, not the original one', () async {
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    now = now.add(const Duration(minutes: 5));
    c.pauseFocus();
    now = now.add(const Duration(minutes: 30));
    c.resumeFocus();
    await Future<void>.delayed(Duration.zero);

    final args = lastNotice()!.arguments as Map<Object?, Object?>;
    expect(args['paused'], isFalse);
    // Twenty minutes were left when it was paused, and half an hour of paused
    // time must not have eaten any of them.
    expect(args['remainingSeconds'], 20 * 60);
    expect(
      args['endsAtMillis'],
      now.add(const Duration(minutes: 20)).millisecondsSinceEpoch,
    );
  });

  test('ending the block takes the countdown away', () async {
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    now = now.add(const Duration(minutes: 25));
    await c.endFocus();

    expect(calls.map((c) => c.method), contains('hideFocusNotice'));
  });

  test('a block restored on open is counted down again', () async {
    // The process died mid-block. Android dropped the notification with it, and
    // the countdown has to come back with the block.
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    await Future<void>.delayed(Duration.zero);
    final db = c.db;

    now = now.add(const Duration(minutes: 10));
    calls.clear();
    final reopened = open(db);
    await reopened.load();

    final args = lastNotice()!.arguments as Map<Object?, Object?>;
    expect(args['remainingSeconds'], 15 * 60);
    expect(args['taskTitle'], 'Write the intro');
  });

  test('nothing is posted when there is no block', () async {
    final c = open(TallyDatabase(NativeDatabase.memory()));
    await c.load();
    expect(lastNotice(), isNull);
  });
}
