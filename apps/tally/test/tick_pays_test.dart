import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// Ticking a task pays its estimate.
///
/// Changed 2026-09-24: the work was often done without starting the timer,
/// and a tick that paid nothing left the balance saying the day had not
/// happened.
const install = '018f2c00-aaaa-7000-8000-000000000001';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late DateTime now;

  Future<TallyController> withPlannedTask({int? estimate = 25}) async {
    now = DateTime.utc(2026, 8, 17, 10);
    final c = TallyController(
      db: TallyDatabase(NativeDatabase.memory()),
      installId: install,
      clock: () => now,
    );
    await c.load();
    final task = await c.createTask(
      TaskDraft(
        kind: TaskKind.oneoff,
        title: 'Write the intro',
        estimateMinutes: estimate,
      ),
    );
    await c.addToToday([task.id]);
    return c;
  }

  int earnedToday(TallyController c) => c.ledger!.days.last.earnedSeconds;

  test('a tick pays the estimate', () async {
    final c = await withPlannedTask();
    final before = c.ledger!.spendableSeconds;

    await c.toggle(c.plan.single);

    expect(earnedToday(c), 25 * 60);
    expect(c.ledger!.spendableSeconds, before + 25 * 60);
  });

  test('unticking takes it back', () async {
    final c = await withPlannedTask();
    final before = c.ledger!.spendableSeconds;

    await c.toggle(c.plan.single);
    await c.toggle(c.plan.single);

    expect(earnedToday(c), 0);
    expect(c.ledger!.spendableSeconds, before);
  });

  test('ticking again after an untick pays once, not twice', () async {
    final c = await withPlannedTask();
    await c.toggle(c.plan.single);
    await c.toggle(c.plan.single);
    await c.toggle(c.plan.single);

    expect(earnedToday(c), 25 * 60);
  });

  test('a task with no estimate is ticked and pays nothing', () async {
    final c = await withPlannedTask(estimate: null);
    await c.toggle(c.plan.single);

    expect(c.plan.single.isDone, isTrue);
    expect(earnedToday(c), 0);
  });

  test('a finished focus block is not paid again by its own tick', () async {
    final c = await withPlannedTask();
    c.startFocus(taskId: c.plan.single.taskId, minutes: 25);
    now = now.add(const Duration(minutes: 25));
    await c.endFocus();
    // The engine counts a session once it has ended strictly before the
    // instant it computes at, so the ledger is read a minute later.
    now = now.add(const Duration(minutes: 1));
    await c.load();

    expect(c.plan.single.isDone, isTrue);
    expect(earnedToday(c), 25 * 60);
  });

  test('a partial block plus a tick pays the estimate, not more', () async {
    final c = await withPlannedTask();
    c.startFocus(taskId: c.plan.single.taskId, minutes: 25);
    now = now.add(const Duration(minutes: 10));
    await c.endFocus();
    now = now.add(const Duration(minutes: 30));

    await c.toggle(c.plan.single);

    expect(earnedToday(c), 25 * 60);
  });

  test('unticking leaves a real focus session alone', () async {
    final c = await withPlannedTask();
    c.startFocus(taskId: c.plan.single.taskId, minutes: 25);
    now = now.add(const Duration(minutes: 25));
    await c.endFocus();
    now = now.add(const Duration(minutes: 1));

    await c.toggle(c.plan.single);

    expect(c.plan.single.isDone, isFalse);
    expect(earnedToday(c), 25 * 60);
  });
}
