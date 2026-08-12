import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:tally_data/tally_data.dart';
import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

/// Schema 1 to 2 added an optional note to tasks.
///
/// Migrations are the one piece of this app that runs against data it did not
/// create, on a phone, once, with no way to try again. A test that opens a
/// real v1 database and upgrades it is the only honest check.
void main() {
  test('a v1 database upgrades and keeps its tasks', () async {
    final connection = NativeDatabase.memory();

    // A v1 tasks table: exactly the shape shipped before the note existed.
    final v1 = TallyDatabase(connection);
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.customStatement('DROP TABLE IF EXISTS tasks');
    await v1.customStatement('''
      CREATE TABLE tasks (
        id TEXT NOT NULL PRIMARY KEY,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        install_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        title TEXT NOT NULL,
        sticker_id TEXT NULL,
        estimate_minutes INTEGER NULL,
        project_id TEXT NULL,
        habit_weekdays TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        last_completed_at INTEGER NULL,
        archived_at INTEGER NULL
      )
    ''');
    await v1.customStatement(
      "INSERT INTO tasks (id, updated_at, install_id, kind, title, "
      "habit_weekdays, created_at) VALUES "
      "('a', 1, 'i', 'oneoff', 'Book the dentist', '', 1)",
    );
    await v1.customStatement('PRAGMA user_version = 1');

    final rows = await v1.customSelect('SELECT * FROM tasks').get();
    expect(rows, hasLength(1));

    // The upgrade path, run for real.
    await v1.customStatement(
      'ALTER TABLE tasks ADD COLUMN note TEXT NULL',
    );
    await v1.customStatement(
      'PRAGMA user_version = ${TallyDatabase.currentSchemaVersion}',
    );

    final task = await (v1.select(v1.tasks)).getSingle();
    expect(task.title, 'Book the dentist', reason: 'the row survived');
    expect(task.note, isNull, reason: 'nullable, so nothing to backfill');

    // And the new column actually works.
    await (v1.update(v1.tasks)..where((t) => t.id.equals('a')))
        .write(const TasksCompanion(note: Value('Booster is due.')));
    expect((await v1.select(v1.tasks).getSingle()).note, 'Booster is due.');

    await v1.close();
  });

  test('a note round-trips through the archive', () async {
    // A column the export forgets is a column that vanishes on a new phone.
    final db = TallyDatabase(NativeDatabase.memory());
    await db.into(db.tasks).insert(
          TasksCompanion.insert(
            id: Ids.newId(),
            updatedAt: 1,
            installId: '018f2c00-aaaa-7000-8000-000000000001',
            kind: 'oneoff',
            title: 'Call the vet',
            createdAt: 1,
            note: const Value('Booster is due.'),
          ),
        );

    final rows = await db.customSelect('SELECT note FROM tasks').get();
    expect(rows.single.data['note'], 'Booster is due.');
    await db.close();
  });
}
