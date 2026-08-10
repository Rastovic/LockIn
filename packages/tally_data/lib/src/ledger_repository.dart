import 'package:drift/drift.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:vitals_archive/vitals_archive.dart';
import 'package:vitals_core/vitals_core.dart';

import 'database.dart';

/// Reads stored rows, runs [LedgerEngine], writes the day rollups back.
///
/// The engine knows nothing about storage and storage knows nothing about the
/// rules. This class is the only place the two meet, which is what keeps the
/// engine portable to iOS unchanged.
final class LedgerRepository {
  LedgerRepository(
    this.db, {
    required this.installId,
    LedgerSettings settings = const LedgerSettings(),
    OffsetResolver? offsetAt,
  })  : _settings = settings,
        _engine = LedgerEngine(
          settings: settings,
          offsetAt: offsetAt ?? _deviceOffset,
        );

  final TallyDatabase db;
  final String installId;
  final LedgerSettings _settings;
  final LedgerEngine _engine;

  LedgerEngine get engine => _engine;

  /// The device's own offset. Sampled per instant rather than once, so a
  /// history spanning a DST change resolves each day with the offset that was
  /// actually in force.
  static int _deviceOffset(DateTime instant) =>
      instant.toLocal().timeZoneOffset.inMinutes;

  /// Recomputes the ledger over a range from stored rows.
  ///
  /// Derived, never incremental: this is called on every app open, every
  /// service start and every reconcile, and it always produces the same answer
  /// from the same rows.
  Future<LedgerResult> recompute({
    required String fromDay,
    required String toDay,
    required DateTime now,
    int openingBalanceSeconds = 0,
    int openingSavingsSeconds = 0,
    int openingStreak = 0,
    int openingBestStreak = 0,
  }) async {
    final sessions = await _loadSessions(fromDay, toDay);
    final spend = await _loadSpend(fromDay, toDay);
    final treats = await _loadTreats(fromDay, toDay);
    final transfers = await _loadTransfers(fromDay, toDay);

    return _engine.compute(
      fromDay: fromDay,
      toDay: toDay,
      now: now,
      sessions: sessions,
      spend: spend,
      treats: treats,
      transfers: transfers,
      openingBalanceSeconds: openingBalanceSeconds,
      openingSavingsSeconds: openingSavingsSeconds,
      openingStreak: openingStreak,
      openingBestStreak: openingBestStreak,
    );
  }

  /// Recomputes and persists the rollups.
  ///
  /// Rows are replaced rather than updated in place: a rollup is derived, so
  /// the stored copy is a cache of a calculation and never a source of truth.
  Future<LedgerResult> recomputeAndStore({
    required String fromDay,
    required String toDay,
    required DateTime now,
    int openingBalanceSeconds = 0,
    int openingSavingsSeconds = 0,
  }) async {
    final result = await recompute(
      fromDay: fromDay,
      toDay: toDay,
      now: now,
      openingBalanceSeconds: openingBalanceSeconds,
      openingSavingsSeconds: openingSavingsSeconds,
    );

    final stamp = now.millisecondsSinceEpoch;
    final offset = _deviceOffset(now);

    await db.transaction(() async {
      for (final day in result.days) {
        await (db.delete(db.dayLedger)
              ..where((t) => t.dayKey.equals(day.dayKey)))
            .go();
        await db.into(db.dayLedger).insert(
              DayLedgerCompanion.insert(
                id: Ids.newId(),
                updatedAt: stamp,
                installId: installId,
                dayKey: day.dayKey,
                tzOffsetMinutes: offset,
                allowanceGrantedSeconds: day.allowanceGrantedSeconds,
                allowanceToDebtSeconds: day.allowanceToDebtSeconds,
                earnedSeconds: day.earnedSeconds,
                earnCappedSeconds: day.earnCappedSeconds,
                spentSeconds: day.spentSeconds,
                graceUsedSeconds: day.graceUsedSeconds,
                unrepayableSeconds: day.unrepayableSeconds,
                closingBalanceSeconds: day.closingBalanceSeconds,
                closingSavingsSeconds: day.closingSavingsSeconds,
                overflowToSavingsSeconds: day.overflowToSavingsSeconds,
                treatedSeconds: day.treatedSeconds,
                solvent: day.solvent,
              ),
            );
      }
    });

    return result;
  }

  /// Recomputes an imported history and compares it against what the archive
  /// claimed.
  ///
  /// **The step that makes a restore trustworthy, and in an app with a ledger
  /// it is free.** It tests the exporter, the importer and the engine at once,
  /// on the user's real data.
  ///
  /// A mismatch keeps the recomputed value, because that one is by definition
  /// correct, and reports the days that differed so the discrepancy is visible
  /// rather than silent.
  Future<ImportVerification> verifyImported({
    required DateTime now,
    int openingBalanceSeconds = 0,
    int openingSavingsSeconds = 0,
  }) async {
    final imported = await db.select(db.dayLedger).get();
    if (imported.isEmpty) {
      return const ImportVerification(checkedDays: 0, mismatchedDays: []);
    }

    final days = imported.map((r) => r.dayKey).toList()..sort();
    final claimed = {for (final row in imported) row.dayKey: row};

    final recomputed = await recompute(
      fromDay: days.first,
      toDay: days.last,
      now: now,
      openingBalanceSeconds: openingBalanceSeconds,
      openingSavingsSeconds: openingSavingsSeconds,
    );

    final mismatched = <String>[];
    for (final day in recomputed.days) {
      final was = claimed[day.dayKey];
      if (was == null) continue;
      if (was.closingBalanceSeconds != day.closingBalanceSeconds ||
          was.earnedSeconds != day.earnedSeconds ||
          was.spentSeconds != day.spentSeconds ||
          was.closingSavingsSeconds != day.closingSavingsSeconds) {
        mismatched.add(day.dayKey);
      }
    }

    return ImportVerification(
      checkedDays: recomputed.days.length,
      mismatchedDays: mismatched,
    );
  }

  Future<List<FocusSession>> _loadSessions(String from, String to) async {
    final rows = await (db.select(db.sessions)
          ..where((t) => t.dayKey.isBetweenValues(from, to))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return [
      for (final row in rows)
        FocusSession(
          id: row.id,
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            row.startedAt,
            isUtc: true,
          ),
          endedAt: DateTime.fromMillisecondsSinceEpoch(
            row.endedAt,
            isUtc: true,
          ),
          taskId: row.taskId,
          phoneDownVerified: row.phoneDownVerified,
        ),
    ];
  }

  /// Loads billable spend with its real position in the day.
  ///
  /// Reads [SpendSpans], not the per-day totals: the ledger is order-sensitive
  /// because grace fires on a zero-crossing, so the same minutes spent before
  /// or after a focus session close at different balances.
  Future<List<UsageSpan>> _loadSpend(String from, String to) async {
    final rows = await (db.select(db.spendSpans)
          ..where((t) => t.dayKey.isBetweenValues(from, to))
          ..where((t) => t.deletedAt.isNull()))
        .get();

    return [
      for (final row in rows)
        if (row.endedAt > row.startedAt)
          UsageSpan(
            packageName: row.packageName,
            start: DateTime.fromMillisecondsSinceEpoch(
              row.startedAt,
              isUtc: true,
            ),
            end: DateTime.fromMillisecondsSinceEpoch(row.endedAt, isUtc: true),
          ),
    ];
  }

  /// Rebuilds the per-app day totals from the spans.
  ///
  /// [DaySpend] is a derived read-model for the Statement's breakdown, so it is
  /// replaced wholesale rather than accumulated.
  Future<void> rebuildDaySpend({
    required String fromDay,
    required String toDay,
    required DateTime now,
  }) async {
    final spans = await _loadSpend(fromDay, toDay);
    final totals = <(String, String), int>{};
    for (final span in spans) {
      final day = _engine.dayKeyAt(span.start);
      totals.update(
        (day, span.packageName),
        (v) => v + span.seconds,
        ifAbsent: () => span.seconds,
      );
    }

    final stamp = now.millisecondsSinceEpoch;
    final offset = _deviceOffset(now);
    await db.transaction(() async {
      await (db.delete(db.daySpend)
            ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay)))
          .go();
      for (final entry in totals.entries) {
        await db.into(db.daySpend).insert(
              DaySpendCompanion.insert(
                id: Ids.newId(),
                updatedAt: stamp,
                installId: installId,
                dayKey: entry.key.$1,
                tzOffsetMinutes: offset,
                packageName: entry.key.$2,
                seconds: entry.value,
              ),
            );
      }
    });
  }

  Future<List<Treat>> _loadTreats(String from, String to) async {
    final rows = await (db.select(db.treats)
          ..where((t) => t.dayKey.isBetweenValues(from, to))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return [
      for (final row in rows)
        Treat(
          id: row.id,
          at: _engine.dayStart(row.dayKey).add(const Duration(hours: 12)),
          seconds: row.minutesBurned * 60,
          label: row.label,
        ),
    ];
  }

  Future<List<SavingsTransfer>> _loadTransfers(String from, String to) async {
    final rows = await (db.select(db.savingsTransfers)
          ..where((t) => t.dayKey.isBetweenValues(from, to))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return [
      for (final row in rows)
        SavingsTransfer(
          id: row.id,
          at: _engine.dayStart(row.dayKey).add(const Duration(hours: 12)),
          seconds: row.seconds,
          toSavings: row.toSavings,
        ),
    ];
  }

  LedgerSettings get settings => _settings;
}
