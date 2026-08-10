import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:tally_data/tally_data.dart';
import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

TallyDatabase openMemory() => TallyDatabase(NativeDatabase.memory());

const install = '018f2c00-aaaa-7000-8000-000000000001';

void main() {
  late TallyDatabase db;

  setUp(() => db = openMemory());
  tearDown(() => db.close());

  group('the portability rules are structural', () {
    test('every travelling table carries the four portable columns', () {
      // Rules 1 to 4 of DATA-PORTABILITY.md. Asserted over the real schema
      // rather than trusted, so a table added later without the mixin fails
      // here instead of six months into production.
      for (final table in db.allTables) {
        if (TallyBackup.deviceLocalTables.contains(table.actualTableName)) {
          continue;
        }
        final columns = {for (final c in table.$columns) c.name};
        expect(columns, contains('id'), reason: table.actualTableName);
        expect(columns, contains('updated_at'), reason: table.actualTableName);
        expect(columns, contains('deleted_at'), reason: table.actualTableName);
        expect(columns, contains('install_id'), reason: table.actualTableName);
      }
    });

    test('no travelling table uses an autoincrement integer key', () {
      // Two devices both minting id = 47 cannot be merged, and that is
      // unfixable once real users hold real history.
      for (final table in db.allTables) {
        if (TallyBackup.deviceLocalTables.contains(table.actualTableName)) {
          continue;
        }
        final id = table.$columns.firstWhere((c) => c.name == 'id');
        expect(
          id.type,
          DriftSqlType.string,
          reason: '${table.actualTableName}.id must be a UUID',
        );
      }
    });

    test('usage_checkpoints is the only device-local table', () {
      // It records how far *this* device reconciled. Exporting it would make a
      // new phone believe it had already counted days it never saw.
      expect(TallyBackup.deviceLocalTables, ['usage_checkpoints']);
      final names = db.allTables.map((t) => t.actualTableName).toSet();
      expect(names, contains('usage_checkpoints'));
    });

    test('day-scoped tables freeze their day key and offset', () {
      // Rule 5: a statement written in Dublin must not change after landing in
      // Tokyo.
      for (final name in ['sessions', 'day_ledger', 'treats', 'sticker_stamps']) {
        final table =
            db.allTables.firstWhere((t) => t.actualTableName == name);
        final columns = {for (final c in table.$columns) c.name};
        expect(columns, contains('day_key'), reason: name);
        expect(columns, contains('tz_offset_minutes'), reason: name);
      }
    });

    test('every duration column is an integer', () {
      // Rule 7: no doubles anywhere in a ledger, ever.
      for (final table in db.allTables) {
        for (final column in table.$columns) {
          if (column.name.endsWith('_seconds') ||
              column.name.endsWith('_minutes')) {
            expect(
              column.type,
              DriftSqlType.int,
              reason: '${table.actualTableName}.${column.name}',
            );
          }
        }
      }
    });

    test('enum-ish columns are text, never ordinals', () {
      // Rule 6: reordering an enum must not reinterpret a year of history.
      final cases = {
        'tasks': 'kind',
        'plan_entries': 'source',
        'goals': 'scope',
        'suggestion_history': 'outcome',
      };
      for (final entry in cases.entries) {
        final table =
            db.allTables.firstWhere((t) => t.actualTableName == entry.key);
        final column =
            table.$columns.firstWhere((c) => c.name == entry.value);
        expect(column.type, DriftSqlType.string, reason: '${entry.key}.${entry.value}');
      }
    });
  });

  group('the database works', () {
    test('creates cleanly and reports its schema version', () async {
      await db.customSelect('SELECT 1').get();
      expect(db.schemaVersion, TallyDatabase.currentSchemaVersion);
    });

    test('foreign keys are on for the connection', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.data.values.first, 1);
    });

    test('the statement indexes exist', () async {
      // Without these the 90-day statement scans, and the plan's 200ms budget
      // on a seeded six-month database is unreachable.
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final names = {for (final r in rows) r.data['name'] as String};
      expect(names, contains('idx_day_ledger_day'));
      expect(names, contains('idx_sessions_day'));
      expect(names, contains('idx_plan_entries_day'));
    });

    test('a task round-trips', () async {
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: Ids.newId(),
              updatedAt: 1000,
              installId: install,
              kind: 'oneoff',
              title: 'clean one surface',
              createdAt: 1000,
            ),
          );
      final tasks = await db.select(db.tasks).get();
      expect(tasks.single.title, 'clean one surface');
      expect(tasks.single.deletedAt, isNull);
    });

    test('a soft delete leaves the row and its tombstone', () async {
      final id = Ids.newId();
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: id,
              updatedAt: 1000,
              installId: install,
              kind: 'oneoff',
              title: 'x',
              createdAt: 1000,
            ),
          );
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        const TasksCompanion(deletedAt: Value(2000), updatedAt: Value(2000)),
      );
      final row = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.deletedAt, 2000, reason: 'a tombstone, not a missing row');
    });
  });
}
