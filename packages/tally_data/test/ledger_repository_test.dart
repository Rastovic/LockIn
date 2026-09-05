import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';
const tiktok = 'com.zhiliaoapp.musically';

TallyDatabase openMemory() => TallyDatabase(NativeDatabase.memory());

/// UTC throughout, so the 4am boundary sits at 04:00 and the numbers read
/// straight off the page.
LedgerRepository repoFor(TallyDatabase db, {LedgerSettings? settings}) =>
    LedgerRepository(
      db,
      installId: install,
      // 30 free minutes and 5 of grace, stated rather than inherited: these
      // cases are about whether stored rows recompute to the right balance, and
      // both shipped defaults are zero - product decisions that should not be
      // able to silently change what these are asserting. Grace especially: the
      // order-sensitivity case below exists *because* grace fires on a
      // zero-crossing, and with grace off there is nothing for the order to
      // change.
      settings: settings ??
          const LedgerSettings(dailyAllowanceMinutes: 30, graceMinutes: 5),
      offsetAt: fixedOffset(0),
    );

DateTime t(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, 8, day, hour, minute);

Future<void> addSession(
  TallyDatabase db, {
  required String dayKey,
  required DateTime start,
  required int minutes,
  bool phoneDown = false,
}) =>
    db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: Ids.newId(),
            updatedAt: 1,
            installId: install,
            dayKey: dayKey,
            tzOffsetMinutes: 0,
            startedAt: start.millisecondsSinceEpoch,
            endedAt:
                start.add(Duration(minutes: minutes)).millisecondsSinceEpoch,
            phoneDownVerified: Value(phoneDown),
          ),
        );

/// Spend with a real position in the day, because the ledger is
/// order-sensitive: grace fires on a zero-crossing, so the same minutes before
/// or after a session close at different balances.
Future<void> addSpend(
  TallyDatabase db, {
  required String dayKey,
  required DateTime start,
  required int minutes,
  String package = tiktok,
}) =>
    db.into(db.spendSpans).insert(
          SpendSpansCompanion.insert(
            id: Ids.newId(),
            updatedAt: 1,
            installId: install,
            dayKey: dayKey,
            tzOffsetMinutes: 0,
            packageName: package,
            startedAt: start.millisecondsSinceEpoch,
            endedAt:
                start.add(Duration(minutes: minutes)).millisecondsSinceEpoch,
          ),
        );

int mins(int seconds) => (seconds / 60).round();

void main() {
  late TallyDatabase db;

  setUp(() => db = openMemory());
  tearDown(() => db.close());

  group('recompute from stored rows', () {
    test('a day of focus and scrolling lands on the right balance', () async {
      await addSession(db, dayKey: '2026-08-11', start: t(11, 9), minutes: 40);
      await addSpend(db, dayKey: '2026-08-11', start: t(11, 14), minutes: 55);

      final result = await repoFor(db).recompute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );

      final day = result.days.single;
      expect(mins(day.earnedSeconds), 40);
      expect(mins(day.spentSeconds), 55);
      // 30 allowance covers the first 30, the 40 earned covers the rest.
      expect(mins(day.closingBalanceSeconds), 15);
    });

    test('spend keeps its position in the day, and that changes the answer',
        () async {
      // The reason spend is stored as spans and not as a per-day total. The
      // ledger is order-sensitive: grace fires on a zero-crossing, so the same
      // 55 minutes before or after a 40 minute session close differently.
      Future<int> closingWith({required DateTime spendAt}) async {
        final fresh = openMemory();
        await addSession(fresh, dayKey: '2026-08-11', start: t(11, 9), minutes: 40);
        await addSpend(fresh, dayKey: '2026-08-11', start: spendAt, minutes: 55);
        final result = await repoFor(fresh).recompute(
          fromDay: '2026-08-11',
          toDay: '2026-08-11',
          now: t(11, 23),
        );
        final closing = result.days.single.closingBalanceSeconds;
        await fresh.close();
        return closing;
      }

      // Scrolling after earning: allowance covers 30, the 40 earned covers the
      // remaining 25, and grace is never touched.
      expect(mins(await closingWith(spendAt: t(11, 14))), 15);
      // Scrolling first: allowance 30, then 5 free minutes of grace, then 20
      // of debt, which the later session repays with 20 left over.
      expect(mins(await closingWith(spendAt: t(11, 5))), 20);
    });

    test('soft-deleted rows are excluded', () async {
      // A tombstone must stop counting immediately. A deleted session that
      // still earns would be a silent way to inflate the balance.
      await addSession(db, dayKey: '2026-08-11', start: t(11, 9), minutes: 40);
      await db.update(db.sessions).write(
            const SessionsCompanion(
              deletedAt: Value(2000),
              updatedAt: Value(2000),
            ),
          );

      final result = await repoFor(db).recompute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );
      expect(result.days.single.earnedSeconds, 0);
    });

    test('a day with nothing stored still produces a rollup', () async {
      final result = await repoFor(db).recompute(
        fromDay: '2026-08-09',
        toDay: '2026-08-11',
        now: t(12, 12),
      );
      expect(result.days, hasLength(3));
      expect(result.days.every((d) => d.solvent), isTrue);
    });

    test('the phone-down bonus survives the round trip through storage', () async {
      await addSession(
        db,
        dayKey: '2026-08-11',
        start: t(11, 9),
        minutes: 20,
        phoneDown: true,
      );
      final result = await repoFor(db).recompute(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );
      expect(mins(result.days.single.earnedSeconds), 30);
    });
  });

  group('recomputeAndStore', () {
    test('writes one rollup per day and no duplicates on a second run', () async {
      // Rollups are a cache of a calculation, so recomputing must replace
      // rather than accumulate. Without this, a statement would double-count
      // after every app open.
      await addSession(db, dayKey: '2026-08-11', start: t(11, 9), minutes: 30);
      final repo = repoFor(db);

      await repo.recomputeAndStore(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );
      await repo.recomputeAndStore(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );

      final rows = await db.select(db.dayLedger).get();
      expect(rows, hasLength(1));
      expect(mins(rows.single.earnedSeconds), 30);
    });

    test('stored rollups match what recompute returned', () async {
      await addSession(db, dayKey: '2026-08-10', start: t(10, 9), minutes: 45);
      await addSpend(db, dayKey: '2026-08-11', start: t(11, 14), minutes: 90);
      final repo = repoFor(db);

      final result = await repo.recomputeAndStore(
        fromDay: '2026-08-10',
        toDay: '2026-08-11',
        now: t(12, 12),
      );

      final rows = await (db.select(db.dayLedger)
            ..orderBy([(t) => OrderingTerm(expression: t.dayKey)]))
          .get();
      expect(rows, hasLength(2));
      for (var i = 0; i < rows.length; i++) {
        expect(rows[i].dayKey, result.days[i].dayKey);
        expect(
          rows[i].closingBalanceSeconds,
          result.days[i].closingBalanceSeconds,
        );
        expect(rows[i].solvent, result.days[i].solvent);
      }
    });

    test('stored rollups carry the portability columns', () async {
      await addSession(db, dayKey: '2026-08-11', start: t(11, 9), minutes: 30);
      await repoFor(db).recomputeAndStore(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );
      final row = await db.select(db.dayLedger).getSingle();
      expect(Ids.isValid(row.id), isTrue);
      expect(row.installId, install);
      expect(row.deletedAt, isNull);
    });
  });

  group('verify by recomputation', () {
    test('a faithful backup verifies clean', () async {
      await addSession(db, dayKey: '2026-08-10', start: t(10, 9), minutes: 40);
      await addSpend(db, dayKey: '2026-08-11', start: t(11, 14), minutes: 20);
      final repo = repoFor(db);

      await repo.recomputeAndStore(
        fromDay: '2026-08-10',
        toDay: '2026-08-11',
        now: t(12, 12),
      );

      final verification = await repo.verifyImported(now: t(12, 12));
      expect(verification.isClean, isTrue);
      expect(verification.checkedDays, 2);
      expect(verification.message, contains('Every day checked out'));
    });

    test('a tampered rollup is caught and named', () async {
      // The whole point: this check tests the exporter, the importer and the
      // engine at once, on the user's real data, and it is free in an app that
      // already recomputes.
      await addSession(db, dayKey: '2026-08-11', start: t(11, 9), minutes: 40);
      final repo = repoFor(db);
      await repo.recomputeAndStore(
        fromDay: '2026-08-11',
        toDay: '2026-08-11',
        now: t(11, 23),
      );

      // Someone hand-edited the archive, or an older buggy version wrote it.
      await db.update(db.dayLedger).write(
            const DayLedgerCompanion(closingBalanceSeconds: Value(999999)),
          );

      final verification = await repo.verifyImported(now: t(11, 23));
      expect(verification.isClean, isFalse);
      expect(verification.mismatchedDays, ['2026-08-11']);
      expect(verification.message, contains('1 of 1'));
      expect(verification.message, contains('recalculated'));
    });

    test('an empty database verifies as nothing to check', () async {
      final verification = await repoFor(db).verifyImported(now: t(11, 23));
      expect(verification.checkedDays, 0);
      expect(verification.isClean, isTrue);
    });

    test('a claimed day with no supporting sessions is caught', () async {
      // The failure mode that matters most for a restore: the archive says the
      // user earned an hour, but no session in it accounts for that hour.
      await db.into(db.dayLedger).insert(
            DayLedgerCompanion.insert(
              id: Ids.newId(),
              updatedAt: 1,
              installId: install,
              dayKey: '2026-08-11',
              tzOffsetMinutes: 0,
              allowanceGrantedSeconds: 1800,
              allowanceToDebtSeconds: 0,
              earnedSeconds: 3600,
              earnCappedSeconds: 0,
              spentSeconds: 0,
              graceUsedSeconds: 0,
              unrepayableSeconds: 0,
              closingBalanceSeconds: 3600,
              closingSavingsSeconds: 0,
              overflowToSavingsSeconds: 0,
              treatedSeconds: 0,
              solvent: true,
            ),
          );

      final verification = await repoFor(db).verifyImported(now: t(11, 23));
      expect(verification.mismatchedDays, ['2026-08-11']);
    });
  });

  group('export, import, verify: the whole chain', () {
    test('a restored history recomputes to the same numbers', () async {
      // The plan's phone-upgrade rehearsal, as far as it can be automated.
      final original = openMemory();
      for (var day = 9; day <= 12; day++) {
        final key = '2026-08-${day.toString().padLeft(2, '0')}';
        await addSession(
          original,
          dayKey: key,
          start: t(day, 9),
          minutes: 20 + day,
          phoneDown: day.isEven,
        );
        await addSpend(original, dayKey: key, start: t(day, 14), minutes: 10 * (day - 8));
      }
      final originalRepo = repoFor(original);
      final before = await originalRepo.recomputeAndStore(
        fromDay: '2026-08-09',
        toDay: '2026-08-12',
        now: t(13, 12),
      );
      final bytes = await TallyBackup(original).export(
        appVersion: '1.0.0',
        installId: install,
        exportedAtMillis: 1786472040000,
        timezone: 'UTC',
        dayBoundaryHour: 4,
      );
      await original.close();

      final restored = openMemory();
      final imported = await TallyBackup(restored).import(bytes);
      expect(imported.error, isNull);

      final restoredRepo = repoFor(restored);
      final verification = await restoredRepo.verifyImported(now: t(13, 12));
      expect(
        verification.isClean,
        isTrue,
        reason: 'restored days: ${verification.mismatchedDays}',
      );

      final after = await restoredRepo.recompute(
        fromDay: '2026-08-09',
        toDay: '2026-08-12',
        now: t(13, 12),
      );
      expect(after.balanceSeconds, before.balanceSeconds);
      expect(after.savingsSeconds, before.savingsSeconds);
      expect(after.bestSolvencyStreak, before.bestSolvencyStreak);
      expect(
        after.days.map((d) => d.closingBalanceSeconds),
        before.days.map((d) => d.closingBalanceSeconds),
      );
      await restored.close();
    });
  });
}
