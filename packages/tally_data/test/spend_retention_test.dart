import 'package:drift/native.dart';
import 'package:tally_data/tally_data.dart';
import 'package:test/test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:vitals_core/vitals_core.dart';

/// Unwatching an app must not erase what it already cost today.
///
/// The reconcile loop replaces stored spend for the packages it just re-read.
/// It once cleared the whole day, which meant unwatching an app at 3pm deleted
/// the time it had already cost and the balance jumped up - the opposite of the
/// rule that removing an app stops future counting and leaves history alone.
const install = '018f2c00-aaaa-7000-8000-000000000001';
const today = '2026-08-11';

void main() {
  late TallyDatabase db;

  setUp(() => db = TallyDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addSpan(String package, int minutes) async {
    await db.into(db.spendSpans).insert(
          SpendSpansCompanion.insert(
            id: Ids.newId(),
            updatedAt: 1,
            installId: install,
            dayKey: today,
            tzOffsetMinutes: 0,
            packageName: package,
            startedAt: DateTime.utc(2026, 8, 11, 10).millisecondsSinceEpoch,
            endedAt: DateTime.utc(2026, 8, 11, 10, minutes)
                .millisecondsSinceEpoch,
          ),
        );
  }

  /// What the controller's reconcile does: clear only the refreshed packages.
  Future<void> refresh(Set<String> packages) async {
    await (db.delete(db.spendSpans)
          ..where((t) => t.dayKey.equals(today))
          ..where((t) => t.packageName.isIn(packages)))
        .go();
  }

  test('refreshing one app leaves another app\'s spend alone', () async {
    await addSpan('com.tiktok', 40);
    await addSpan('com.instagram', 15);

    // The user unwatched Instagram, so only TikTok is re-read.
    await refresh({'com.tiktok'});

    final rows = await db.select(db.spendSpans).get();
    expect(rows.map((r) => r.packageName), ['com.instagram']);
  });

  test('refreshing an app does clear its own stale rows', () async {
    // The source returns the whole window every call, so appending would
    // double-count on every reconcile.
    await addSpan('com.tiktok', 40);
    await refresh({'com.tiktok'});
    expect(await db.select(db.spendSpans).get(), isEmpty);
  });

  test('an unwatched app keeps its history for the ledger', () async {
    await addSpan('com.tiktok', 40);
    await addSpan('com.instagram', 20);
    await refresh({'com.tiktok'});

    final ledger = LedgerRepository(
      db,
      installId: install,
      offsetAt: fixedOffset(0),
    );
    final result = await ledger.recompute(
      fromDay: today,
      toDay: today,
      now: DateTime.utc(2026, 8, 11, 23),
    );
    // The 20 minutes Instagram cost before it was unwatched are still counted.
    expect((result.days.single.spentSeconds / 60).round(), 20);
  });
}
