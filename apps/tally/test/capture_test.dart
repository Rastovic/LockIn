import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally/platform/android_home_widget.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// Capture from the home screen.
///
/// Kotlin holds words; Dart turns them into tasks. That split is what keeps
/// the database to a single writer while making capture instant enough to be
/// worth using.
const install = '018f2c00-aaaa-7000-8000-000000000001';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tally/usage');

  late List<String> queue;
  late int drains;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    queue = [];
    drains = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'drainCaptures') {
        drains++;
        final items = List<String>.from(queue);
        // Read and cleared together, exactly like the Kotlin side.
        queue = [];
        return items;
      }
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
        homeWidget: const AndroidHomeWidget(),
        clock: () => DateTime.utc(2026, 8, 14, 10),
      );

  test('captured lines become real tasks, marked for sorting', () async {
    queue = ['Book the dentist', 'Ask about the boiler'];
    final c = open(TallyDatabase(NativeDatabase.memory()));
    await c.load();

    expect(c.tasks.map((t) => t.title), [
      'Book the dentist',
      'Ask about the boiler',
    ]);
    // Real tasks from the moment they are captured, not entries in a holding
    // pen that has to be promoted out of.
    expect(c.tasks.every((t) => t.needsSorting), isTrue);
    expect(c.tasks.every((t) => t.kind == TaskKind.oneoff), isTrue);
  });

  test('the queue is drained once, not re-imported on every load', () async {
    queue = ['Book the dentist'];
    final db = TallyDatabase(NativeDatabase.memory());
    final c = open(db);
    await c.load();
    await c.load();

    expect(drains, 2, reason: 'asked each time');
    expect(c.tasks, hasLength(1), reason: 'but the line arrived once');
  });

  test('sorting one clears the flag', () async {
    queue = ['Book the dentist'];
    final c = open(TallyDatabase(NativeDatabase.memory()));
    await c.load();

    final captured = c.tasks.single;
    // Opening the sheet and saving is the act of sorting. Anything else would
    // leave things in the inbox the user had already dealt with.
    await c.updateTask(
      captured,
      TaskDraft(
        kind: TaskKind.projectTask,
        title: captured.title,
        estimateMinutes: 30,
      ),
    );

    final sorted = c.tasks.single;
    expect(sorted.needsSorting, isFalse);
    expect(sorted.kind, TaskKind.projectTask);
    expect(sorted.estimateMinutes, 30);
  });

  test('a capture survives a restart before it is sorted', () async {
    queue = ['Book the dentist'];
    final db = TallyDatabase(NativeDatabase.memory());
    await open(db).load();

    final reopened = open(db);
    await reopened.load();
    expect(reopened.tasks.single.needsSorting, isTrue);
  });

  test('blank captures are dropped rather than becoming empty tasks',
      () async {
    queue = ['   ', ''];
    final c = open(TallyDatabase(NativeDatabase.memory()));
    await c.load();
    expect(c.tasks, isEmpty);
  });
}
