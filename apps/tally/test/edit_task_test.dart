import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// Editing a task must not quietly drop the parts the edit did not touch.
///
/// `updateTask` builds a Task field by field from the draft, which means every
/// field added to Task after that call was written is silently omitted and
/// nothing fails to compile. The description went missing exactly this way:
/// added to the model, the column and the sheet, and dropped on every save.
const install = '018f2c00-aaaa-7000-8000-000000000001';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<TallyController> open() async {
    final c = TallyController(
      db: TallyDatabase(NativeDatabase.memory()),
      installId: install,
      clock: () => DateTime.utc(2026, 8, 14, 10),
    );
    await c.load();
    return c;
  }

  test('an edit keeps the description, the repeat and the project', () async {
    final c = await open();
    final project = await c.createProject('Dissertation');

    await c.createTask(
      const TaskDraft(
        kind: TaskKind.quick,
        title: 'Take supplements',
        note: 'The vitamin D and the magnesium.',
        repeat: TaskRepeat.daily,
      ),
    );
    final made = c.tasks.single;

    // A rename, and nothing else touched.
    await c.updateTask(
      made,
      TaskDraft(
        kind: made.kind,
        title: 'Take the supplements',
        note: made.note,
        repeat: made.repeat,
        projectId: made.projectId,
      ),
    );

    final edited = c.tasks.single;
    expect(edited.title, 'Take the supplements');
    expect(edited.note, 'The vitamin D and the magnesium.');
    expect(edited.repeat, TaskRepeat.daily);

    // And a project task keeps its project through an edit that says nothing
    // about projects.
    await c.createTask(
      TaskDraft(
        kind: TaskKind.projectTask,
        title: 'Read the Barron paper',
        projectId: project.id,
      ),
    );
    final filed = c.tasks.firstWhere((t) => t.title == 'Read the Barron paper');
    expect(filed.projectId, project.id);

    await c.updateTask(
      filed,
      TaskDraft(
        kind: filed.kind,
        title: 'Read the Barron paper again',
        projectId: filed.projectId,
      ),
    );
    expect(
      c.tasks.firstWhere((t) => t.title.startsWith('Read')).projectId,
      project.id,
    );
  });

  test('a daily task is offered again the next day', () async {
    // The end to end version of the planner test: it has to survive being
    // written to the database and read back, not just computed.
    final db = TallyDatabase(NativeDatabase.memory());
    final monday = TallyController(
      db: db,
      installId: install,
      clock: () => DateTime.utc(2026, 8, 14, 10),
    );
    await monday.load();
    await monday.createTask(
      const TaskDraft(
        kind: TaskKind.quick,
        title: 'Take supplements',
        repeat: TaskRepeat.daily,
      ),
    );
    expect(monday.today.view.offeredHabits, hasLength(1));

    final id = monday.tasks.single.id;
    await monday.addToToday([id]);
    await monday.toggle(monday.plan.single);
    expect(monday.today.view.offeredHabits, isEmpty, reason: 'done for today');

    final tuesday = TallyController(
      db: db,
      installId: install,
      clock: () => DateTime.utc(2026, 8, 15, 10),
    );
    await tuesday.load();
    expect(
      tuesday.today.view.offeredHabits.map((t) => t.title),
      ['Take supplements'],
    );
  });
}
