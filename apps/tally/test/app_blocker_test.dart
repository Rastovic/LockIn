import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally/platform/android_app_blocker.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';

/// What the app blocker is handed.
///
/// Android only subtracts usage since the instant it is given, so the two
/// things that must be right here are the figure and that instant. Everything
/// else about the ledger stays in Dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tally/usage');
  late List<MethodCall> calls;
  late bool systemSwitch;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    systemSwitch = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'blockerOn') return systemSwitch;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Map<Object?, Object?> lastPush() => calls
      .lastWhere((c) => c.method == 'updateBlocking')
      .arguments as Map<Object?, Object?>;

  Future<TallyController> controller({
    required UsageSource usage,
    DateTime? at,
  }) async {
    final db = TallyDatabase(NativeDatabase.memory());
    final c = TallyController(
      db: db,
      installId: install,
      usageSource: usage,
      appBlocker: const AndroidAppBlocker(),
      clock: () => at ?? DateTime.utc(2026, 9, 17, 10),
    );
    await c.load();
    await c.setWatching(
      const WatchableApp(
        packageName: 'com.feed',
        label: 'Feed',
        recentSeconds: 0,
      ),
      true,
    );
    return c;
  }

  test('off by default, and the push says so', () async {
    final c = await controller(usage: FakeUsageSource());
    expect(c.blockMode, BlockMode.off);
    expect(lastPush()['enabled'], isFalse);
  });

  test('turning it on sends the watched apps and the balance', () async {
    final c = await controller(usage: FakeUsageSource());
    await c.setBlockMode(BlockMode.block);

    final push = lastPush();
    expect(push['enabled'], isTrue);
    expect(push['hard'], isTrue);
    expect(jsonDecode(push['packages']! as String), ['com.feed']);
    expect(push['spendableSeconds'], c.ledger?.spendableSeconds ?? 0);
  });

  test('the switch survives a relaunch', () async {
    final c = await controller(usage: FakeUsageSource());
    await c.setBlockMode(BlockMode.block);

    final reopened = TallyController(
      db: c.db,
      installId: install,
      usageSource: FakeUsageSource(),
      appBlocker: const AndroidAppBlocker(),
      clock: () => DateTime.utc(2026, 9, 17, 11),
    );
    await reopened.load();
    expect(reopened.blockMode, BlockMode.block);
  });

  test('without usage access nothing is blocked, whatever the switch says',
      () async {
    // The blocker would be subtracting from spend it cannot see. A block with
    // no count behind it is a guess.
    final c = await controller(
      usage: FakeUsageSource(accessState: UsageAccess.denied),
    );
    await c.setBlockMode(BlockMode.block);
    expect(lastPush()['enabled'], isFalse);
  });

  test('usage is counted from when it was read, not from the last push',
      () async {
    var clock = DateTime.utc(2026, 9, 17, 10);
    final db = TallyDatabase(NativeDatabase.memory());
    final c = TallyController(
      db: db,
      installId: install,
      usageSource: FakeUsageSource(),
      appBlocker: const AndroidAppBlocker(),
      clock: () => clock,
    );
    await c.load();
    await c.setWatching(
      const WatchableApp(
        packageName: 'com.feed',
        label: 'Feed',
        recentSeconds: 0,
      ),
      true,
    );
    final readAt = clock;

    // Twenty minutes later, a change that recomputes without re-reading
    // usage. Counting from now would forgive those twenty minutes.
    clock = clock.add(const Duration(minutes: 20));
    await c.setBlockMode(BlockMode.block);

    expect(lastPush()['asOfMillis'], readAt.millisecondsSinceEpoch);
  });

  test('the system switch is read on load', () async {
    systemSwitch = true;
    final c = await controller(usage: FakeUsageSource());
    expect(c.blockerOn, isTrue);
  });

  test('the push says when the figure stops being today\'s', () async {
    final c = await controller(usage: FakeUsageSource());
    await c.setBlockMode(BlockMode.block);
    // Default boundary is 4am, so today's figure is good until 4am tomorrow.
    final until = DateTime.fromMillisecondsSinceEpoch(
      lastPush()['validUntilMillis']! as int,
      isUtc: true,
    );
    expect(until.isAfter(DateTime.utc(2026, 9, 17, 10)), isTrue);
    expect(until.difference(DateTime.utc(2026, 9, 17, 10)).inHours, lessThan(25));
  });

  test('remind is on, but not hard, so the page offers a way through',
      () async {
    final c = await controller(usage: FakeUsageSource());
    await c.setBlockMode(BlockMode.remind);

    final push = lastPush();
    expect(push['enabled'], isTrue);
    expect(push['hard'], isFalse);
  });

  test('turning it off again sends it disabled', () async {
    final c = await controller(usage: FakeUsageSource());
    await c.setBlockMode(BlockMode.remind);
    await c.setBlockMode(BlockMode.off);
    expect(lastPush()['enabled'], isFalse);
  });
}
