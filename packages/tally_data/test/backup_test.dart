import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:tally_data/tally_data.dart';
import 'package:test/test.dart';
import 'package:vitals_archive/vitals_archive.dart';
import 'package:vitals_core/vitals_core.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';

TallyDatabase openMemory() => TallyDatabase(NativeDatabase.memory());

/// Fills a database with a plausible slice of real use.
Future<void> seed(TallyDatabase db) async {
  final taskId = Ids.newId();
  await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: taskId,
          updatedAt: 1000,
          installId: install,
          kind: 'habit',
          title: 'piano',
          createdAt: 1000,
          habitWeekdays: const Value('2,4'),
          estimateMinutes: const Value(20),
          stickerId: const Value('music'),
        ),
      );

  for (var day = 9; day <= 11; day++) {
    final dayKey = '2026-08-${day.toString().padLeft(2, '0')}';
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: Ids.newId(),
            updatedAt: 1000,
            installId: install,
            dayKey: dayKey,
            tzOffsetMinutes: 60,
            startedAt: 1000,
            endedAt: 2200,
            taskId: Value(taskId),
            phoneDownVerified: Value(day.isEven),
          ),
        );
    await db.into(db.dayLedger).insert(
          DayLedgerCompanion.insert(
            id: Ids.newId(),
            updatedAt: 1000,
            installId: install,
            dayKey: dayKey,
            tzOffsetMinutes: 60,
            allowanceGrantedSeconds: 1800,
            allowanceToDebtSeconds: 0,
            earnedSeconds: 1200,
            earnCappedSeconds: 0,
            spentSeconds: 900,
            graceUsedSeconds: 0,
            unrepayableSeconds: 0,
            closingBalanceSeconds: 300,
            closingSavingsSeconds: 0,
            overflowToSavingsSeconds: 0,
            treatedSeconds: 0,
            solvent: true,
          ),
        );
  }

  await db.into(db.watchedApps).insert(
        WatchedAppsCompanion.insert(
          id: Ids.newId(),
          updatedAt: 1000,
          installId: install,
          packageName: 'com.zhiliaoapp.musically',
          label: 'TikTok',
          addedAt: 1000,
        ),
      );

  await db.into(db.treats).insert(
        TreatsCompanion.insert(
          id: Ids.newId(),
          updatedAt: 1000,
          installId: install,
          dayKey: '2026-08-11',
          tzOffsetMinutes: 60,
          minutesBurned: 90,
          label: 'cinema',
        ),
      );

  await db.into(db.stickerStamps).insert(
        StickerStampsCompanion.insert(
          id: Ids.newId(),
          updatedAt: 1000,
          installId: install,
          dayKey: '2026-08-11',
          tzOffsetMinutes: 60,
          stickerId: 'music',
          taskId: taskId,
          stampedAt: 1000,
        ),
      );

  await db.into(db.goals).insert(
        GoalsCompanion.insert(
          id: Ids.newId(),
          updatedAt: 1000,
          installId: install,
          scope: 'year',
          title: 'finish the thesis',
          createdAt: 1000,
        ),
      );

  // Device-local, and must not travel.
  await db.into(db.usageCheckpoints).insert(
        UsageCheckpointsCompanion.insert(
          reconciledThrough: 999999,
          recordedAt: 999999,
        ),
      );
}

Future<Map<String, List<Map<String, Object?>>>> dump(TallyDatabase db) async {
  final out = <String, List<Map<String, Object?>>>{};
  for (final table in db.allTables) {
    final rows = await db
        .customSelect('SELECT * FROM ${table.actualTableName} ORDER BY rowid')
        .get();
    out[table.actualTableName] = [for (final r in rows) r.data];
  }
  return out;
}

Future<List<int>> exportOf(TallyDatabase db) => TallyBackup(db).export(
      appVersion: '1.0.0',
      installId: install,
      exportedAtMillis: 1786472040000,
      timezone: 'Europe/Dublin',
      dayBoundaryHour: 4,
      device: const {'model': 'Pixel 7a'},
    );

void main() {
  group('export, wipe, import', () {
    test('every number comes back identical', () async {
      // The test that catches real bugs, straight from the plan: export, wipe,
      // import, and assert the app would render the same numbers.
      final original = openMemory();
      await seed(original);
      final before = await dump(original);
      final bytes = await exportOf(original);
      await original.close();

      final restored = openMemory();
      final result = await TallyBackup(restored).import(
        Uint8List.fromList(bytes),
      );
      expect(result.error, isNull);

      final after = await dump(restored);
      for (final table in TallyBackup.exportedTables) {
        expect(
          after[table],
          before[table],
          reason: '$table did not survive the round trip',
        );
      }
      await restored.close();
    });

    test('usage checkpoints do not travel to the new device', () async {
      // They record how far *this* device reconciled. Importing them would make
      // a new phone believe it had already counted days it never saw, and the
      // first reconcile would silently skip them.
      final original = openMemory();
      await seed(original);
      final bytes = await exportOf(original);
      await original.close();

      final restored = openMemory();
      await TallyBackup(restored).import(Uint8List.fromList(bytes));
      final checkpoints = await restored.select(restored.usageCheckpoints).get();
      expect(checkpoints, isEmpty);
      await restored.close();
    });

    test('the preview describes what is about to happen', () async {
      final original = openMemory();
      await seed(original);
      final bytes = await exportOf(original);
      await original.close();

      final restored = openMemory();
      final result = await TallyBackup(restored).import(
        Uint8List.fromList(bytes),
      );
      final preview = result.applied!;
      expect(preview.summary, contains('3 sessions'));
      expect(preview.summary, contains('3 days'));
      expect(preview.summary, contains('2026-08-09 to 2026-08-11'));
      expect(preview.hadLosses, isFalse);
      await restored.close();
    });

    test('replace mode wipes what was there first', () async {
      final original = openMemory();
      await seed(original);
      final bytes = await exportOf(original);
      await original.close();

      final target = openMemory();
      await target.into(target.goals).insert(
            GoalsCompanion.insert(
              id: Ids.newId(),
              updatedAt: 500,
              installId: '018f2c00-bbbb-7000-8000-000000000002',
              scope: 'life',
              title: 'a goal from the old data',
              createdAt: 500,
            ),
          );

      await TallyBackup(target).import(Uint8List.fromList(bytes));
      final goals = await target.select(target.goals).get();
      expect(goals.map((g) => g.title), ['finish the thesis']);
      await target.close();
    });
  });

  group('refusals leave the database untouched', () {
    test('an archive from a newer app is refused and nothing is written', () async {
      final db = openMemory();
      await seed(db);
      final before = await dump(db);

      // Forge a manifest claiming a future schema.
      final writer = ArchiveWriter(
        manifest: ArchiveManifest(
          app: 'tally',
          appVersion: '99.0.0',
          schemaVersion: TallyDatabase.currentSchemaVersion + 5,
          installId: install,
          exportedAt: 1,
          timezone: 'UTC',
          rowCounts: const {'goals': 1},
        ),
      )..addTable('goals', [
          {'id': 'x', 'updatedAt': 1, 'installId': 'y', 'scope': 'year'},
        ]);

      final result = await TallyBackup(db).import(writer.build());
      expect(result.error!.reason, ArchiveRejection.futureSchema);
      expect(await dump(db), before, reason: 'no partial write');
      await db.close();
    });

    test('a truncated archive is refused and nothing is written', () async {
      final db = openMemory();
      await seed(db);
      final before = await dump(db);

      final good = await exportOf(db);
      final truncated = Uint8List.fromList(good.sublist(0, good.length ~/ 2));

      final result = await TallyBackup(db).import(truncated);
      expect(result.error, isNotNull);
      expect(await dump(db), before);
      await db.close();
    });
  });

  group('cross-device realities', () {
    test('an unknown column from another version does not fail the row', () async {
      // A backup written by a schema that has since lost a column must still
      // restore. Dropping the column is right; failing the row is not.
      final db = openMemory();
      final writer = ArchiveWriter(
        manifest: ArchiveManifest(
          app: 'tally',
          appVersion: '0.9.0',
          schemaVersion: 1,
          installId: install,
          exportedAt: 1,
          timezone: 'UTC',
          rowCounts: const {'goals': 1},
        ),
      )..addTable('goals', [
          {
            'id': Ids.newId(),
            'updated_at': 1,
            'install_id': install,
            'scope': 'year',
            'title': 'from an older build',
            'created_at': 1,
            'a_column_that_no_longer_exists': 'ignored',
          },
        ]);

      final result = await TallyBackup(db).import(writer.build());
      expect(result.error, isNull);
      final goals = await db.select(db.goals).get();
      expect(goals.single.title, 'from an older build');
      await db.close();
    });

    test('a watched app missing on this phone still restores', () async {
      // Keep the row, mark it, show it greyed with its history intact. It must
      // never fail the import.
      final original = openMemory();
      await original.into(original.watchedApps).insert(
            WatchedAppsCompanion.insert(
              id: Ids.newId(),
              updatedAt: 1000,
              installId: install,
              packageName: 'com.app.that.is.gone',
              label: 'Gone',
              addedAt: 1000,
              notInstalled: const Value(true),
            ),
          );
      final bytes = await exportOf(original);
      await original.close();

      final restored = openMemory();
      final result = await TallyBackup(restored).import(
        Uint8List.fromList(bytes),
      );
      expect(result.error, isNull);
      final apps = await restored.select(restored.watchedApps).get();
      expect(apps.single.notInstalled, isTrue);
      expect(apps.single.label, 'Gone');
      await restored.close();
    });
  });

  group('the archive is the wire format', () {
    test('a manifest records what a future sync would need', () async {
      final db = openMemory();
      await seed(db);
      final bytes = await exportOf(db);
      final contents = const ArchiveReader()
          .read(
            Uint8List.fromList(bytes),
            appSchemaVersion: TallyDatabase.currentSchemaVersion,
          )
          .contents!;

      expect(contents.manifest.installId, install);
      expect(contents.manifest.dayBoundaryHour, 4);
      expect(contents.manifest.schemaVersion, 1);

      // Every travelling row carries the merge keys, which is what makes this
      // file a sync payload rather than only a backup.
      for (final table in contents.tables.values) {
        for (final row in table.rows) {
          expect(row.containsKey('id'), isTrue, reason: table.table);
          expect(row.containsKey('updated_at'), isTrue, reason: table.table);
          expect(row.containsKey('install_id'), isTrue, reason: table.table);
        }
      }
      await db.close();
    });
  });
}
