import 'package:drift/native.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';
const today = '2026-08-11';
final now = DateTime.utc(2026, 8, 11, 9);

const planner = TodayPlanner();

void main() {
  late TallyDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = TallyDatabase(NativeDatabase.memory());
    repo = TaskRepository(db, installId: install);
  });
  tearDown(() => db.close());

  group('tasks survive a round trip', () {
    test('a habit keeps its weekdays, sticker and estimate', () async {
      await repo.createTask(
        kind: TaskKind.habit,
        title: 'Piano',
        now: now,
        stickerId: 'music',
        estimateMinutes: 20,
        habitWeekdays: const {2, 4},
      );

      final loaded = (await repo.tasks()).single;
      expect(loaded.kind, TaskKind.habit);
      expect(loaded.title, 'Piano');
      expect(loaded.stickerId, 'music');
      expect(loaded.estimateMinutes, 20);
      expect(loaded.habitWeekdays, {2, 4});
    });

    test('a task with no sticker or estimate round-trips as null', () async {
      // Most tasks carry neither, so the common case has to be the clean one.
      await repo.createTask(
        kind: TaskKind.oneoff,
        title: 'Book the dentist',
        now: now,
      );
      final loaded = (await repo.tasks()).single;
      expect(loaded.stickerId, isNull);
      expect(loaded.estimateMinutes, isNull);
      expect(loaded.habitWeekdays, isEmpty);
    });

    test('titles are trimmed on the way in', () async {
      await repo.createTask(
        kind: TaskKind.oneoff,
        title: '  Gym  ',
        now: now,
      );
      expect((await repo.tasks()).single.title, 'Gym');
    });

    test('every row carries the portability columns', () async {
      final task = await repo.createTask(
        kind: TaskKind.oneoff,
        title: 'x',
        now: now,
      );
      final row = await db.select(db.tasks).getSingle();
      expect(Ids.isValid(task.id), isTrue);
      expect(row.installId, install);
      expect(row.updatedAt, now.millisecondsSinceEpoch);
      expect(row.deletedAt, isNull);
    });

    test('an unknown kind from a newer version degrades to a one-off',
        () async {
      // Enums are stored as strings so this stays recoverable rather than
      // crashing the whole list on a downgrade.
      await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      await db.customStatement("UPDATE tasks SET kind = 'something_new'");
      expect((await repo.tasks()).single.kind, TaskKind.oneoff);
    });
  });

  group('deleting and archiving', () {
    test('a delete leaves a tombstone, not a hole', () async {
      final task =
          await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      await repo.deleteTask(task.id, now: now);

      expect(await repo.tasks(), isEmpty);
      final row = await db.select(db.tasks).getSingle();
      expect(row.deletedAt, isNotNull, reason: 'the row is still there');
    });

    test('deleting a task tombstones its plan entries too', () async {
      // Otherwise the plan keeps a row pointing at a task that no longer
      // exists, and the day silently loses a line with no explanation.
      final task =
          await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      await repo.savePlan(
        dayKey: today,
        entries: planner.addToDay(
          dayKey: today,
          plan: const [],
          taskIds: [task.id],
        ),
        now: now,
      );
      expect(await repo.planFor(today), hasLength(1));

      await repo.deleteTask(task.id, now: now);
      expect(await repo.planFor(today), isEmpty);
    });

    test('archiving hides the task and keeps its history', () async {
      final task =
          await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      await repo.archiveTask(task.id, now: now);

      final loaded = (await repo.tasks()).single;
      expect(loaded.isArchived, isTrue, reason: 'still loadable');
    });
  });

  group('the day plan', () {
    test('saves, loads and keeps the user order', () async {
      final ids = <String>[];
      for (final title in ['a', 'b', 'c']) {
        ids.add(
          (await repo.createTask(
            kind: TaskKind.oneoff,
            title: title,
            now: now,
          ))
              .id,
        );
      }

      var plan =
          planner.addToDay(dayKey: today, plan: const [], taskIds: ids);
      plan = planner.reorder(
        dayKey: today,
        plan: plan,
        fromIndex: 2,
        toIndex: 0,
      );
      await repo.savePlan(dayKey: today, entries: plan, now: now);

      final loaded = await repo.planFor(today);
      expect(loaded.map((e) => e.taskId), [ids[2], ids[0], ids[1]]);
      expect(loaded.map((e) => e.sortOrder), [0, 1, 2]);
    });

    test('completion survives a reload', () async {
      final task =
          await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      var plan = planner
          .addToDay(dayKey: today, plan: const [], taskIds: [task.id]);
      plan = planner
          .complete(
            plan: plan,
            entryId: plan.single.id,
            tasks: [task],
            at: now,
            dayKey: today,
          )
          .plan;
      await repo.savePlan(dayKey: today, entries: plan, now: now);

      expect((await repo.planFor(today)).single.isDone, isTrue);
    });

    test('a row removed from the plan is tombstoned, not deleted', () async {
      // A removal that leaves no tombstone comes back on the next merge.
      final task =
          await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      final plan = planner
          .addToDay(dayKey: today, plan: const [], taskIds: [task.id]);
      await repo.savePlan(dayKey: today, entries: plan, now: now);
      await repo.savePlan(dayKey: today, entries: const [], now: now);

      expect(await repo.planFor(today), isEmpty);
      final row = await db.select(db.planEntries).getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('saving twice does not duplicate rows', () async {
      final task =
          await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      final plan = planner
          .addToDay(dayKey: today, plan: const [], taskIds: [task.id]);
      await repo.savePlan(dayKey: today, entries: plan, now: now);
      await repo.savePlan(dayKey: today, entries: plan, now: now);

      expect(await db.select(db.planEntries).get(), hasLength(1));
    });

    test('another day is untouched', () async {
      final task =
          await repo.createTask(kind: TaskKind.oneoff, title: 'x', now: now);
      await repo.savePlan(
        dayKey: '2026-08-10',
        entries: planner
            .addToDay(dayKey: '2026-08-10', plan: const [], taskIds: [task.id]),
        now: now,
      );
      await repo.savePlan(dayKey: today, entries: const [], now: now);

      expect(await repo.planFor('2026-08-10'), hasLength(1));
    });
  });

  group('sticker stamps', () {
    test('a completion stamps, and unticking leaves no trace', () async {
      final task = await repo.createTask(
        kind: TaskKind.oneoff,
        title: 'Dishes',
        now: now,
        stickerId: 'dishes',
      );
      var plan = planner
          .addToDay(dayKey: today, plan: const [], taskIds: [task.id]);
      final done = planner.complete(
        plan: plan,
        entryId: plan.single.id,
        tasks: [task],
        at: now,
        dayKey: today,
      );
      plan = done.plan;
      await repo.addStamp(done.stamp!, now: now);
      expect(await repo.stampsFor(today), hasLength(1));

      await repo.removeStampsFor(taskId: task.id, dayKey: today, now: now);
      expect(await repo.stampsFor(today), isEmpty);
    });
  });

  group('habit streaks are derived, never stored', () {
    Future<void> markDone(String taskId, String dayKey, Task task) async {
      var plan =
          planner.addToDay(dayKey: dayKey, plan: const [], taskIds: [taskId]);
      plan = planner
          .complete(
            plan: plan,
            entryId: plan.single.id,
            tasks: [task],
            at: now,
            dayKey: dayKey,
          )
          .plan;
      await repo.savePlan(dayKey: dayKey, entries: plan, now: now);
    }

    test('counts back from today', () async {
      final task = await repo.createTask(
        kind: TaskKind.habit,
        title: 'Piano',
        now: now,
      );
      for (final day in ['2026-08-09', '2026-08-10', '2026-08-11']) {
        await markDone(task.id, day, task);
      }
      expect(await repo.habitStreaks(dayKey: today), {task.id: 3});
    });

    test('today not yet done does not break the streak', () async {
      // The day is still running. Counting from yesterday is the only reading
      // that does not punish someone for opening the app in the morning.
      final task = await repo.createTask(
        kind: TaskKind.habit,
        title: 'Piano',
        now: now,
      );
      for (final day in ['2026-08-09', '2026-08-10']) {
        await markDone(task.id, day, task);
      }
      expect(await repo.habitStreaks(dayKey: today), {task.id: 2});
    });

    test('a gap ends the streak', () async {
      final task = await repo.createTask(
        kind: TaskKind.habit,
        title: 'Piano',
        now: now,
      );
      for (final day in ['2026-08-07', '2026-08-10', '2026-08-11']) {
        await markDone(task.id, day, task);
      }
      expect(await repo.habitStreaks(dayKey: today), {task.id: 2});
    });

    test('a task never completed has no streak at all', () async {
      final task = await repo.createTask(
        kind: TaskKind.habit,
        title: 'Piano',
        now: now,
      );
      await repo.savePlan(
        dayKey: today,
        entries: planner
            .addToDay(dayKey: today, plan: const [], taskIds: [task.id]),
        now: now,
      );
      expect(await repo.habitStreaks(dayKey: today), isEmpty);
    });
  });

  group('sessions', () {
    test('a finished block is stored and reaches the ledger', () async {
      final run = FocusRun(
        id: Ids.newId(),
        startedAt: DateTime.utc(2026, 8, 11, 9),
        planned: const Duration(minutes: 25),
      ).finish(DateTime.utc(2026, 8, 11, 9, 25));

      await repo.addSession(run.toSession(now)!, dayKey: today, now: now);

      final ledger = LedgerRepository(
        db,
        installId: install,
        offsetAt: fixedOffset(0),
      );
      final result = await ledger.recompute(
        fromDay: today,
        toDay: today,
        now: DateTime.utc(2026, 8, 11, 23),
      );
      expect((result.days.single.earnedSeconds / 60).round(), 25);
    });
  });

  group('a whole day, persisted', () {
    test('plan, tick, reload, and everything is where it was', () async {
      // The dogfood test: the app is closed and reopened, and nothing is lost.
      final gym = await repo.createTask(
        kind: TaskKind.habit,
        title: 'Gym',
        now: now,
        estimateMinutes: 45,
        habitWeekdays: const {2},
      );
      final dishes = await repo.createTask(
        kind: TaskKind.oneoff,
        title: 'Dishes',
        now: now,
        stickerId: 'dishes',
        estimateMinutes: 15,
      );

      var plan = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: [gym.id, dishes.id],
      );
      final done = planner.complete(
        plan: plan,
        entryId: plan.last.id,
        tasks: [gym, dishes],
        at: now,
        dayKey: today,
      );
      plan = done.plan;
      await repo.savePlan(dayKey: today, entries: plan, now: now);
      await repo.addStamp(done.stamp!, now: now);

      // Reopen: a fresh repository over the same database.
      final reopened = TaskRepository(db, installId: install);
      final tasks = await reopened.tasks();
      final view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: await reopened.planFor(today),
        now: now,
      );

      expect(view.rows.map((r) => r.task.title), ['Gym', 'Dishes']);
      expect(view.rows.last.isDone, isTrue);
      expect(view.plannedMinutes, 60);
      expect(await reopened.stampsFor(today), hasLength(1));
    });
  });
}
