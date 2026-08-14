import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/platform/android_home_widget.dart';
import 'package:tally_engine/tally_engine.dart';

/// What the home screen widget is handed.
///
/// Dart resolves everything the widget shows, so Kotlin never learns what a
/// sticker id means or how a day is assembled. These tests pin that contract:
/// they are the only thing standing between a schema change here and a widget
/// that quietly renders blanks on someone's home screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tally/usage');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  TodayView viewOf(List<Task> tasks, {Set<String> done = const {}}) =>
      const TodayPlanner().buildToday(
        dayKey: '2026-08-14',
        tasks: tasks,
        plan: [
          for (var i = 0; i < tasks.length; i++)
            PlanEntry(
              id: 'e$i',
              dayKey: '2026-08-14',
              taskId: tasks[i].id,
              sortOrder: i,
              source: PlanSource.manual,
              doneAt: done.contains(tasks[i].id)
                  ? DateTime.utc(2026, 8, 14, 11)
                  : null,
            ),
        ],
        now: DateTime.utc(2026, 8, 14, 12),
      );

  Task task(String id, {String? sticker}) => Task(
        id: id,
        kind: TaskKind.oneoff,
        title: id,
        createdAt: DateTime.utc(2026, 8, 1),
        stickerId: sticker,
      );

  test('sends the plan in order, with glyphs already resolved', () async {
    await const AndroidHomeWidget().push(
      view: viewOf(
        [task('Dishes', sticker: 'dishes'), task('Gym', sticker: 'gym')],
        done: {'Dishes'},
      ),
      dateLabel: 'Fri 14 August',
      spendableSeconds: 900,
      usageVisible: true,
    );

    expect(calls.single.method, 'updateTodayWidget');
    final args = calls.single.arguments as Map;
    expect(args['dateLabel'], 'Fri 14 August');
    expect(args['doneCount'], 1);
    expect(args['totalCount'], 2);

    final rows = jsonDecode(args['rows'] as String) as List;
    expect(rows, hasLength(2));
    expect(rows[0]['title'], 'Dishes');
    expect(rows[0]['done'], isTrue);
    // The glyph, not the id: Kotlin has no sticker catalogue and must not
    // need one.
    expect(rows[0]['glyph'], '🍽');
    expect(rows[1]['done'], isFalse);
  });

  test('says nothing about minutes without usage access', () async {
    // A confident zero would be a claim the app cannot make yet, and it would
    // read as "you have spent everything" rather than "this is switched off".
    await const AndroidHomeWidget().push(
      view: viewOf([task('Dishes')]),
      dateLabel: 'Fri 14 August',
      spendableSeconds: 0,
      usageVisible: false,
    );
    expect((calls.single.arguments as Map)['usageVisible'], isFalse);
  });

  test('a task with no sticker sends an empty glyph, not a null', () async {
    // The Kotlin side puts this straight into a TextView. A null would render
    // as the string "null" on someone's home screen.
    await const AndroidHomeWidget().push(
      view: viewOf([task('Dishes')]),
      dateLabel: 'Fri 14 August',
      spendableSeconds: 0,
      usageVisible: true,
    );
    final rows =
        jsonDecode((calls.single.arguments as Map)['rows'] as String) as List;
    expect(rows.single['glyph'], '');
  });

  test('an empty day still pushes, so the widget clears', () async {
    // The failure this prevents: yesterday's tasks sitting on the home screen
    // under today's date because nothing was sent for an empty plan.
    await const AndroidHomeWidget().push(
      view: viewOf(const []),
      dateLabel: 'Fri 14 August',
      spendableSeconds: 0,
      usageVisible: true,
    );
    expect(calls, hasLength(1));
    expect(jsonDecode((calls.single.arguments as Map)['rows'] as String), []);
  });

  test('a runaway plan is capped rather than sent whole', () async {
    await const AndroidHomeWidget().push(
      view: viewOf([for (var i = 0; i < 200; i++) task('Task $i')]),
      dateLabel: 'Fri 14 August',
      spendableSeconds: 0,
      usageVisible: true,
    );
    final args = calls.single.arguments as Map;
    final rows = jsonDecode(args['rows'] as String) as List;
    expect(rows, hasLength(AndroidHomeWidget.maxRows));
    // The count is the real one, so the widget's summary never lies about the
    // day just because the list was trimmed for transport.
    expect(args['totalCount'], 200);
  });
}
