import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

const planner = TodayPlanner();

// 2026-08-11 is a Tuesday. ISO weekday 2.
const today = '2026-08-11';
const tomorrow = '2026-08-12';

DateTime at(int hour, [int day = 11]) => DateTime.utc(2026, 8, day, hour);

Task task(
  String id, {
  TaskKind kind = TaskKind.oneoff,
  String? sticker,
  int? estimate,
  Set<int> weekdays = const {},
  DateTime? created,
  DateTime? lastCompleted,
  DateTime? archived,
}) =>
    Task(
      id: id,
      kind: kind,
      title: id,
      createdAt: created ?? at(8),
      stickerId: sticker,
      estimateMinutes: estimate,
      habitWeekdays: weekdays,
      lastCompletedAt: lastCompleted,
      archivedAt: archived,
    );

List<PlanEntry> plan(List<Task> tasks, {String day = today}) =>
    planner.addToDay(dayKey: day, plan: const [], taskIds: [
      for (final t in tasks) t.id,
    ]);

void main() {
  group('buildToday', () {
    test('rows come back in the user order, not insertion order', () {
      final tasks = [task('a'), task('b'), task('c')];
      var entries = plan(tasks);
      entries = planner.reorder(
        dayKey: today,
        plan: entries,
        fromIndex: 2,
        toIndex: 0,
      );
      final view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: entries,
        now: at(9),
      );
      expect(view.rows.map((r) => r.task.id), ['c', 'a', 'b']);
    });

    test('planned minutes total the estimates', () {
      final tasks = [
        task('a', estimate: 10),
        task('b', estimate: 45),
        task('c'),
      ];
      final view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: plan(tasks),
        now: at(9),
      );
      // Eight tasks reading as "6h 20m planned" is the whole self-correction
      // mechanism, so the total must include rows with no estimate as zero
      // rather than dropping them.
      expect(view.plannedMinutes, 55);
      expect(view.rows, hasLength(3));
    });

    test('a deleted task leaves the plan valid rather than throwing', () {
      final tasks = [task('a'), task('b')];
      final entries = plan(tasks);
      final view = planner.buildToday(
        dayKey: today,
        tasks: [tasks.first], // 'b' was deleted while it sat in today's plan
        plan: entries,
        now: at(9),
      );
      expect(view.rows.map((r) => r.task.id), ['a']);
    });

    test('an archived task drops out of today', () {
      final tasks = [task('a'), task('b', archived: at(9))];
      final view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: plan(tasks),
        now: at(10),
      );
      expect(view.rows.map((r) => r.task.id), ['a']);
    });

    test('only this day is shown', () {
      final tasks = [task('a'), task('b')];
      final entries = [
        ...plan([tasks.first]),
        ...plan([tasks.last], day: tomorrow),
      ];
      final view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: entries,
        now: at(9),
      );
      expect(view.rows.map((r) => r.task.id), ['a']);
    });

    test('empty and all-done states are distinguishable', () {
      final empty = planner.buildToday(
        dayKey: today,
        tasks: const [],
        plan: const [],
        now: at(9),
      );
      expect(empty.isEmpty, isTrue);
      // An empty day is not a finished day. The copy for the two differs, so
      // the states must not collapse into each other.
      expect(empty.allDone, isFalse);
    });
  });

  group('habits', () {
    test('a habit due today is offered exactly once', () {
      final habit = task('piano', kind: TaskKind.habit, weekdays: {2});
      final view = planner.buildToday(
        dayKey: today,
        tasks: [habit],
        plan: const [],
        now: at(9),
      );
      expect(view.offeredHabits.map((t) => t.id), ['piano']);
      expect(view.rows, isEmpty, reason: 'offered, never auto-added');
    });

    test('a habit not due today is not offered', () {
      final habit = task('piano', kind: TaskKind.habit, weekdays: {6, 7});
      final view = planner.buildToday(
        dayKey: today,
        tasks: [habit],
        plan: const [],
        now: at(9),
      );
      expect(view.offeredHabits, isEmpty);
    });

    test('a habit with no weekdays is due every day', () {
      final habit = task('water', kind: TaskKind.habit);
      final view = planner.buildToday(
        dayKey: today,
        tasks: [habit],
        plan: const [],
        now: at(9),
      );
      expect(view.offeredHabits, hasLength(1));
    });

    test('an accepted habit stops being offered and appears once', () {
      final habit = task('piano', kind: TaskKind.habit, weekdays: {2});
      final entries = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: ['piano'],
        source: PlanSource.habit,
      );
      final view = planner.buildToday(
        dayKey: today,
        tasks: [habit],
        plan: entries,
        now: at(9),
      );
      expect(view.offeredHabits, isEmpty);
      expect(view.rows, hasLength(1));
      expect(view.rows.single.entry.source, PlanSource.habit);
    });

    test('accepting the same habit twice still yields one row', () {
      var entries = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: ['piano'],
      );
      entries = planner.addToDay(
        dayKey: today,
        plan: entries,
        taskIds: ['piano'],
      );
      expect(entries, hasLength(1));
    });

    test('an archived habit is never offered', () {
      final habit = task(
        'piano',
        kind: TaskKind.habit,
        weekdays: {2},
        archived: at(8),
      );
      final view = planner.buildToday(
        dayKey: today,
        tasks: [habit],
        plan: const [],
        now: at(9),
      );
      expect(view.offeredHabits, isEmpty);
    });
  });

  group('completion pays a sticker, never a minute', () {
    test('ticking a stickered task stamps once', () {
      final tasks = [task('dishes', sticker: 'dishes')];
      final entries = plan(tasks);
      final result = planner.complete(
        plan: entries,
        entryId: entries.single.id,
        tasks: tasks,
        at: at(19),
        dayKey: today,
      );
      expect(result.stamp, isNotNull);
      expect(result.stamp!.stickerId, 'dishes');
      expect(result.plan.single.isDone, isTrue);
    });

    test('ticking an unstickered task is still valid, with no stamp', () {
      final tasks = [task('email')];
      final entries = plan(tasks);
      final result = planner.complete(
        plan: entries,
        entryId: entries.single.id,
        tasks: tasks,
        at: at(19),
        dayKey: today,
      );
      expect(result.stamp, isNull);
      expect(result.plan.single.isDone, isTrue);
    });

    test('ticking twice does not stamp twice', () {
      final tasks = [task('dishes', sticker: 'dishes')];
      var entries = plan(tasks);
      final first = planner.complete(
        plan: entries,
        entryId: entries.single.id,
        tasks: tasks,
        at: at(19),
        dayKey: today,
      );
      entries = first.plan;
      final second = planner.complete(
        plan: entries,
        entryId: entries.single.id,
        tasks: tasks,
        at: at(20),
        dayKey: today,
      );
      expect(second.stamp, isNull);
    });

    test('unticking removes the stamp and leaves no trace', () {
      // Mis-taps are guaranteed. Undoing one must cost nothing.
      final tasks = [task('dishes', sticker: 'dishes')];
      final entries = plan(tasks);
      final done = planner.complete(
        plan: entries,
        entryId: entries.single.id,
        tasks: tasks,
        at: at(19),
        dayKey: today,
      );
      final undone = planner.uncomplete(
        plan: done.plan,
        stamps: [done.stamp!],
        entryId: entries.single.id,
      );
      expect(undone.plan.single.isDone, isFalse);
      expect(undone.stamps, isEmpty);
    });

    test('the planner has no vocabulary for minutes at all', () {
      // Enforcement by type. TodayView exposes planned estimate seconds and
      // nothing that could be credited, and complete() returns a stamp or
      // nothing. There is no code path from a checkbox to the ledger because
      // the two engines share no type that carries credit.
      final tasks = [task('a', estimate: 30, sticker: 's')];
      final entries = plan(tasks);
      final result = planner.complete(
        plan: entries,
        entryId: entries.single.id,
        tasks: tasks,
        at: at(19),
        dayKey: today,
      );
      expect(result.stamp, isA<StickerStamp>());
      final view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: result.plan,
        now: at(20),
      );
      // The only seconds on the view are the user's own estimate, which is a
      // plan, not a payout.
      expect(view.plannedSeconds, 30 * 60);
      expect(view.allDone, isTrue);
    });
  });

  group('reorder', () {
    test('renumbers densely so an order survives a rebuild', () {
      final tasks = [task('a'), task('b'), task('c')];
      final entries = planner.reorder(
        dayKey: today,
        plan: plan(tasks),
        fromIndex: 0,
        toIndex: 2,
      );
      final orders = entries.map((e) => e.sortOrder).toList()..sort();
      expect(orders, [0, 1, 2]);
    });

    test('does not disturb another day', () {
      final tasks = [task('a'), task('b')];
      final entries = [
        ...plan(tasks),
        ...plan([task('z')], day: tomorrow),
      ];
      final moved = planner.reorder(
        dayKey: today,
        plan: entries,
        fromIndex: 0,
        toIndex: 1,
      );
      final other = moved.firstWhere((e) => e.dayKey == tomorrow);
      expect(other.sortOrder, 0);
    });

    test('rejects an out-of-range move', () {
      final tasks = [task('a')];
      expect(
        () => planner.reorder(
          dayKey: today,
          plan: plan(tasks),
          fromIndex: 0,
          toIndex: 5,
        ),
        throwsRangeError,
      );
    });
  });

  group('the day boundary', () {
    test('undone rows are dropped and never carried forward', () {
      // The single most important tone decision in the day layer. Auto-carrying
      // turns a planner into a guilt archive.
      final tasks = [task('a'), task('b')];
      var entries = plan(tasks);
      entries = planner
          .complete(
            plan: entries,
            entryId: entries.first.id,
            tasks: tasks,
            at: at(19),
            dayKey: today,
          )
          .plan;

      final closed = planner.closeDay(dayKey: today, plan: entries);
      expect(closed.droppedTaskIds, ['b']);
      expect(closed.plan, hasLength(1));
      expect(closed.plan.single.isDone, isTrue);

      // Nothing appeared on tomorrow.
      final tomorrowView = planner.buildToday(
        dayKey: tomorrow,
        tasks: tasks,
        plan: closed.plan,
        now: at(9, 12),
      );
      expect(tomorrowView.rows, isEmpty);
    });

    test('a dropped task returns to the pool, still available', () {
      final tasks = [task('a')];
      final closed = planner.closeDay(dayKey: today, plan: plan(tasks));
      final pool = planner.pool(
        tasks: tasks,
        plan: closed.plan,
        dayKey: tomorrow,
      );
      expect(pool.map((t) => t.id), ['a']);
    });

    test('closing a day does not touch another day', () {
      final tasks = [task('a')];
      final entries = [...plan(tasks), ...plan([task('z')], day: tomorrow)];
      final closed = planner.closeDay(dayKey: today, plan: entries);
      expect(closed.plan.map((e) => e.dayKey), [tomorrow]);
    });
  });

  group('avoided days', () {
    test('a dread task counts up from when it was created', () {
      final dread = task(
        'apartment',
        kind: TaskKind.dread,
        created: DateTime.utc(2026, 7, 12),
      );
      expect(planner.avoidedDaysFor(dread, now: at(9)), 30);
    });

    test('counts from the last completion once there is one', () {
      final dread = task(
        'apartment',
        kind: TaskKind.dread,
        created: DateTime.utc(2026, 6, 1),
        lastCompleted: DateTime.utc(2026, 8, 1),
      );
      expect(planner.avoidedDaysFor(dread, now: at(9)), 10);
    });

    test('other kinds report zero', () {
      expect(
        planner.avoidedDaysFor(
          task('a', created: DateTime.utc(2026, 1, 1)),
          now: at(9),
        ),
        0,
      );
    });

    test('never goes negative on a clock that moved backwards', () {
      final dread = task(
        'a',
        kind: TaskKind.dread,
        created: DateTime.utc(2026, 12, 1),
      );
      expect(planner.avoidedDaysFor(dread, now: at(9)), 0);
    });
  });

  group('pool', () {
    test('excludes what is already planned today', () {
      final tasks = [task('a'), task('b')];
      final pool = planner.pool(
        tasks: tasks,
        plan: plan([tasks.first]),
        dayKey: today,
      );
      expect(pool.map((t) => t.id), ['b']);
    });

    test('excludes archived tasks', () {
      final tasks = [task('a'), task('b', archived: at(8))];
      final pool = planner.pool(tasks: tasks, plan: const [], dayKey: today);
      expect(pool.map((t) => t.id), ['a']);
    });
  });

  group('a real day, end to end', () {
    test('plan three, focus one, tick another, minutes come only from focus', () {
      final tasks = [
        task('counter', kind: TaskKind.oneoff, sticker: 'cleaning', estimate: 10),
        task('gym', kind: TaskKind.habit, weekdays: {2}, estimate: 45),
        task('cancel sub', kind: TaskKind.dread, sticker: 'admin'),
      ];
      var entries = plan(tasks);

      var view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: entries,
        now: at(8),
      );
      expect(view.rows, hasLength(3));
      expect(view.plannedMinutes, 55);

      // A focus session is started from row 2 and completed. That, and only
      // that, is what the ledger sees.
      final ledger = LedgerEngine(offsetAt: fixedOffset(0)).compute(
        fromDay: today,
        toDay: today,
        now: at(23),
        sessions: [
          FocusSession(
            id: 'f',
            startedAt: at(10),
            endedAt: at(11),
            taskId: 'gym',
          ),
        ],
      );

      // Row 1 is ticked by hand.
      final done = planner.complete(
        plan: entries,
        entryId: entries.first.id,
        tasks: tasks,
        at: at(12),
        dayKey: today,
      );
      entries = done.plan;

      view = planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: entries,
        now: at(13),
      );
      expect(view.doneCount, 1);
      expect(done.stamp!.stickerId, 'cleaning');

      // 60 minutes focused, capped at 90, so 60 credited. The ticked task
      // contributed nothing, which is the rule the whole app rests on.
      expect((ledger.days.single.earnedSeconds / 60).round(), 60);
    });
  });
  group('repeating tasks come back', () {
    /// The first version tied repeating to TaskKind.quick, which made every
    /// quick task daily by definition. Wrong in both directions: a quick job
    /// you only need to do once had nowhere to go, and nothing of any other
    /// kind could repeat at all.
    Task repeating(String id, {TaskRepeat repeat = TaskRepeat.daily}) => Task(
          id: id,
          kind: TaskKind.quick,
          title: id,
          createdAt: DateTime.utc(2026, 8, 1),
          repeat: repeat,
        );

    test('a daily task is offered every day', () {
      const planner = TodayPlanner();
      for (final day in ['2026-08-14', '2026-08-15', '2026-08-16']) {
        final view = planner.buildToday(
          dayKey: day,
          tasks: [repeating('supplements')],
          plan: const [],
          now: DateTime.utc(2026, 8, 16, 9),
        );
        expect(
          view.offeredHabits.map((t) => t.id),
          ['supplements'],
          reason: day,
        );
      }
    });

    test('a one-time task is never offered', () {
      final view = const TodayPlanner().buildToday(
        dayKey: '2026-08-14',
        tasks: [repeating('call the plumber', repeat: TaskRepeat.once)],
        plan: const [],
        now: DateTime.utc(2026, 8, 14, 9),
      );
      expect(view.offeredHabits, isEmpty);
    });

    test('it is not offered again once it is in today', () {
      // Offered, never auto-added, and never offered twice: ticking it should
      // not put it straight back on the list.
      final view = const TodayPlanner().buildToday(
        dayKey: '2026-08-14',
        tasks: [repeating('supplements')],
        plan: [
          PlanEntry(
            id: 'e1',
            dayKey: '2026-08-14',
            taskId: 'supplements',
            sortOrder: 0,
            source: PlanSource.manual,
          ),
        ],
        now: DateTime.utc(2026, 8, 14, 9),
      );
      expect(view.offeredHabits, isEmpty);
      expect(view.rows, hasLength(1));
    });

    test('repeating is independent of kind', () {
      // Any kind can repeat, and a quick task need not. What comes back
      // tomorrow is not something the app can infer from what sort of thing
      // it is.
      final view = const TodayPlanner().buildToday(
        dayKey: '2026-08-14',
        tasks: [
          Task(
            id: 'bins',
            kind: TaskKind.dread,
            title: 'Put the bins out',
            createdAt: DateTime.utc(2026, 8, 1),
            repeat: TaskRepeat.daily,
          ),
        ],
        plan: const [],
        now: DateTime.utc(2026, 8, 14, 9),
      );
      expect(view.offeredHabits.map((t) => t.id), ['bins']);
    });

    test('an archived repeating task stops being offered', () {
      final view = const TodayPlanner().buildToday(
        dayKey: '2026-08-14',
        tasks: [
          Task(
            id: 'old',
            kind: TaskKind.quick,
            title: 'Old',
            createdAt: DateTime.utc(2026, 8, 1),
            repeat: TaskRepeat.daily,
            archivedAt: DateTime.utc(2026, 8, 10),
          ),
        ],
        plan: const [],
        now: DateTime.utc(2026, 8, 14, 9),
      );
      expect(view.offeredHabits, isEmpty);
    });
  });

}
