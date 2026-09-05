import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// Finishing a block should tick the task it was for.
///
/// Reported after a weekend of real use: the timer ran out and the task sat
/// there unticked, so the day never looked finished no matter how much of it
/// was done.
const install = '018f2c00-aaaa-7000-8000-000000000001';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late DateTime now;
  TallyController open(TallyDatabase db) => TallyController(
        db: db,
        installId: install,
        clock: () => now,
      );

  Future<(TallyController, Task)> withPlannedTask() async {
    now = DateTime.utc(2026, 8, 17, 10);
    final c = open(TallyDatabase(NativeDatabase.memory()));
    await c.load();
    final task = await c.createTask(
      const TaskDraft(
        kind: TaskKind.oneoff,
        title: 'Write the intro',
        stickerId: 'write',
        estimateMinutes: 25,
      ),
    );
    await c.addToToday([task.id]);
    return (c, task);
  }

  test('a completed block ticks its task', () async {
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);

    now = now.add(const Duration(minutes: 25));
    await c.endFocus();

    expect(c.plan.single.isDone, isTrue);
  });

  test('and stamps the sticker, exactly as ticking by hand would', () async {
    // Two paths to "done" that leave different state behind is how the second
    // currency quietly stops matching the first.
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    now = now.add(const Duration(minutes: 25));
    await c.endFocus();

    final stamps = await c.db.select(c.db.stickerStamps).get();
    expect(stamps, hasLength(1));
    expect(stamps.single.stickerId, 'write');
    expect(stamps.single.taskId, task.id);
  });

  test('giving up early does not tick it', () async {
    // The user saying they did not do the thing.
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);

    now = now.add(const Duration(minutes: 4));
    await c.endFocus();

    expect(c.plan.single.isDone, isFalse);
  });

  test('a block with no task ticks nothing', () async {
    final (c, _) = await withPlannedTask();
    c.startFocus(minutes: 25);
    now = now.add(const Duration(minutes: 25));
    await c.endFocus();
    expect(c.plan.single.isDone, isFalse);
  });

  test('an already ticked task is not toggled back off', () async {
    // The failure this prevents: finishing a block on something already done
    // un-ticking it, which would also pull the sticker back.
    final (c, task) = await withPlannedTask();
    await c.toggle(c.plan.single);
    expect(c.plan.single.isDone, isTrue);

    c.startFocus(taskId: task.id, minutes: 25);
    now = now.add(const Duration(minutes: 25));
    await c.endFocus();

    expect(c.plan.single.isDone, isTrue);
    expect(await c.db.select(c.db.stickerStamps).get(), hasLength(1));
  });

  group('a block that ran out while the app was closed', () {
    // The gap the alarm left. It rings on time, but nothing in Dart runs behind
    // it: the block was only settled by the focus screen watching the countdown
    // hit zero, which needs the app open on that screen. So the timer went off,
    // the phone went down, and the task sat unticked until it was ticked by hand
    // - after the work had already been done.
    Future<TallyController> reopenAfter(Duration away) async {
      final (c, task) = await withPlannedTask();
      c.startFocus(taskId: task.id, minutes: 25);
      final db = c.db;

      // The process dies mid-block and the user comes back later.
      now = now.add(away);
      final reopened = open(db);
      await reopened.load();
      return reopened;
    }

    test('is settled on the next open, and its task is ticked', () async {
      final c = await reopenAfter(const Duration(minutes: 30));

      expect(c.focus, isNull, reason: 'not still counting');
      expect(c.plan.single.isDone, isTrue);
    });

    test('earns the block, not the hours the phone spent on a table', () async {
      // The bug this exists for: settling at the moment of noticing rather than
      // the moment the clock ran out. A 25 minute block reopened the next
      // morning would bank nine hours of focus, which is the app paying out for
      // a phone face down on a table.
      final c = await reopenAfter(const Duration(hours: 9));

      final sessions = await c.db.select(c.db.sessions).get();
      expect(sessions, hasLength(1));
      final session = sessions.single;
      final seconds = (session.endedAt - session.startedAt) ~/ 1000;
      expect(seconds, 25 * 60);
    });

    test('a block still running is left alone', () async {
      final c = await reopenAfter(const Duration(minutes: 5));

      expect(c.focus, isNotNull);
      expect(c.plan.single.isDone, isFalse);
    });

    test('a paused block is waiting, not finished', () async {
      // Paused has no end to aim at. Someone who paused and went to bed comes
      // back to the block they left.
      final (c, task) = await withPlannedTask();
      c.startFocus(taskId: task.id, minutes: 25);
      now = now.add(const Duration(minutes: 5));
      c.pauseFocus();
      final db = c.db;

      now = now.add(const Duration(hours: 9));
      final reopened = open(db);
      await reopened.load();

      expect(reopened.focus, isNotNull);
      expect(reopened.focus!.isPaused, isTrue);
      expect(reopened.plan.single.isDone, isFalse);
    });
  });

  test('the session is still recorded either way', () async {
    // Ticking is about the task. Minutes are earned by the block, and giving
    // up early still earns what was actually focused.
    final (c, task) = await withPlannedTask();
    c.startFocus(taskId: task.id, minutes: 25);
    now = now.add(const Duration(minutes: 10));
    await c.endFocus();

    expect(await c.db.select(c.db.sessions).get(), hasLength(1));
    expect(c.plan.single.isDone, isFalse);
  });
}
