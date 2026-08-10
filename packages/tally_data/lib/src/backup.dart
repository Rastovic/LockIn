import 'package:drift/drift.dart';
import 'package:vitals_archive/vitals_archive.dart';

import 'database.dart';

/// Exports and restores the whole database.
///
/// The rules that are not obvious from the code:
///
/// - `usage_checkpoints` is **never exported**. It records how far *this
///   device* has reconciled and means nothing on another phone. After a
///   restore, reconciliation resumes from the import moment forward.
/// - `day_ledger` is exported but treated as **derived** on import: the caller
///   recomputes it from sessions and spend, then compares. A mismatch warns and
///   keeps the recomputed value, because that one is by definition correct.
/// - Import is **atomic**: everything is written inside one transaction, so a
///   crash or a cancel leaves the existing data untouched.
final class TallyBackup {
  const TallyBackup(this.db);

  final TallyDatabase db;

  /// Tables that travel, in a fixed order so two exports of the same data
  /// produce byte-identical archives and can be diffed.
  static const exportedTables = [
    'tasks',
    'projects',
    'sessions',
    'plan_entries',
    'watched_apps',
    'day_ledger',
    'day_spend',
    'treats',
    'savings_transfers',
    'sticker_stamps',
    'goals',
    'suggestion_history',
    'settings',
    'meta',
  ];

  /// Tables deliberately left out of every archive.
  static const deviceLocalTables = ['usage_checkpoints'];

  /// Derived tables, exported only so an import can check itself.
  static const derivedTables = ['day_ledger', 'day_spend'];

  List<TableInfo<Table, dynamic>> get _tables => [
        for (final table in db.allTables)
          if (!deviceLocalTables.contains(table.actualTableName)) table,
      ];

  /// Builds the archive.
  Future<Uint8List> export({
    required String appVersion,
    required String installId,
    required int exportedAtMillis,
    required String timezone,
    required int dayBoundaryHour,
    Map<String, String> device = const {},
  }) async {
    final data = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
      final rows = await db.customSelect(
        'SELECT * FROM ${table.actualTableName}',
      ).get();
      data[table.actualTableName] = [for (final row in rows) row.data];
    }

    final writer = ArchiveWriter(
      manifest: ArchiveManifest(
        app: 'tally',
        appVersion: appVersion,
        schemaVersion: db.schemaVersion,
        installId: installId,
        exportedAt: exportedAtMillis,
        timezone: timezone,
        dayBoundaryHour: dayBoundaryHour,
        device: device,
        rowCounts: {
          for (final entry in data.entries) entry.key: entry.value.length,
        },
      ),
    );
    for (final name in data.keys.toList()..sort()) {
      writer.addTable(name, data[name]!);
    }
    return writer.build();
  }

  /// Reads an archive and writes it in, atomically.
  ///
  /// Returns the preview that was applied, or the error that stopped it. The
  /// caller is expected to have shown that preview and taken a confirmation
  /// first: a restore must never be a surprise.
  Future<({ImportPreview? applied, ArchiveError? error})> import(
    Uint8List zipBytes, {
    ImportMode mode = ImportMode.replace,
  }) async {
    final read = const ArchiveReader().read(
      zipBytes,
      appSchemaVersion: db.schemaVersion,
    );
    if (read.error != null) return (applied: null, error: read.error);

    final contents = read.contents!;
    final preview = const ImportPlanner().preview(contents, mode: mode);

    // One transaction. A crash, a low-memory kill or a cancel mid-import
    // leaves the existing data exactly as it was.
    await db.transaction(() async {
      if (mode == ImportMode.replace) {
        for (final table in _tables) {
          await db.customStatement('DELETE FROM ${table.actualTableName}');
        }
      }

      for (final table in _tables) {
        final name = table.actualTableName;
        final rows = contents.tables[name]?.rows;
        if (rows == null || rows.isEmpty) continue;

        final columns = {for (final c in table.$columns) c.name};
        for (final row in rows) {
          // Unknown columns from an older archive are dropped rather than
          // failing the row: a schema that gained a column must still be able
          // to read a backup written before it existed.
          final kept = <String, Object?>{
            for (final entry in row.entries)
              if (columns.contains(entry.key)) entry.key: entry.value,
          };
          if (kept.isEmpty) continue;

          final placeholders = List.filled(kept.length, '?').join(', ');
          final columnList = kept.keys.join(', ');
          await db.customStatement(
            'INSERT OR REPLACE INTO $name ($columnList) VALUES ($placeholders)',
            kept.values.toList(),
          );
        }
      }
    });

    return (applied: preview, error: null);
  }
}
