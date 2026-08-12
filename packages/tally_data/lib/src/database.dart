import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// Tally's database.
///
/// **Schema version is the whole game for restore.** An archive written at a
/// higher version is refused outright; a lower one migrates forward through
/// [migration], the same chain the live database uses. One migration path, and
/// the restore path shares it.
@DriftDatabase(
  tables: [
    Tasks,
    Projects,
    Sessions,
    PlanEntries,
    WatchedApps,
    UsageCheckpoints,
    DayLedger,
    SpendSpans,
    DaySpend,
    Treats,
    SavingsTransfers,
    StickerStamps,
    Goals,
    SuggestionHistory,
    Settings,
    AppMeta,
  ],
)
class TallyDatabase extends _$TallyDatabase {
  TallyDatabase(super.e);

  /// Bumped for every schema change, and written into every archive manifest.
  static const currentSchemaVersion = 2;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          // Migration steps land here as the schema grows. Each one must be
          // additive or explicitly lossy with a note, because this chain also
          // carries a two-year-old backup forward on restore.
          //
          // 1 -> 2: tasks gain an optional note. Additive and nullable, so
          // every existing row is already valid at the new version and there
          // is nothing to backfill.
          if (from < 2) {
            await m.addColumn(tasks, tasks.note);
          }
          await _createIndexes();
        },
        beforeOpen: (details) async {
          // Foreign keys are off by default in SQLite and must be enabled per
          // connection, not once at creation.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Indexes for the queries the app actually runs.
  ///
  /// Every statement screen reads `day_ledger` by day key, and the Insights tab
  /// reads sessions by day. Without these the 90-day statement scans, and the
  /// plan's 200ms budget on a seeded six-month database is unreachable.
  Future<void> _createIndexes() async {
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_day_ledger_day '
          'ON day_ledger (day_key)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_day ON sessions (day_key)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_task ON sessions (task_id)',
      'CREATE INDEX IF NOT EXISTS idx_plan_entries_day '
          'ON plan_entries (day_key, sort_order)',
      'CREATE INDEX IF NOT EXISTS idx_day_spend_day ON day_spend (day_key)',
      'CREATE INDEX IF NOT EXISTS idx_spend_spans_day ON spend_spans (day_key)',
      'CREATE INDEX IF NOT EXISTS idx_sticker_stamps_day '
          'ON sticker_stamps (day_key)',
      'CREATE INDEX IF NOT EXISTS idx_treats_day ON treats (day_key)',
      // Soft-deleted rows are excluded from nearly every read, so the
      // tombstone column earns an index of its own.
      'CREATE INDEX IF NOT EXISTS idx_tasks_deleted ON tasks (deleted_at)',
    ];
    for (final statement in statements) {
      await customStatement(statement);
    }
  }
}
