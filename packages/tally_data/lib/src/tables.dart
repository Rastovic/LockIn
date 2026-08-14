/// Tally's schema v1.
///
/// Every table except [UsageCheckpoints] carries [PortableTable], so every row
/// has a UUID id, an `updatedAt` merge key, a `deletedAt` tombstone and the
/// `installId` that wrote it. Checkpoints are deliberately excluded: they
/// describe *this device's* reconciliation progress and mean nothing on
/// another phone.
///
/// Enums are stored as **strings, never ordinals** (rule 6). Reordering an enum
/// must not silently reinterpret a year of history.
///
/// Durations are **integer seconds** (rule 7). No doubles anywhere in a ledger.
library;

import 'package:drift/drift.dart';
import 'package:vitals_archive/vitals_archive.dart';

/// Habits, project tasks, dread tasks and one-offs.
@DataClassName('TaskRow')
class Tasks extends Table with PortableTable {
  /// `habit` / `projectTask` / `dread` / `oneoff`.
  TextColumn get kind => text()();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// The longer version, when the title is not enough on its own.
  ///
  /// Optional and unstructured on purpose. It holds what the task actually
  /// involves, or why it has been sitting there, and nothing in the ledger
  /// reads it: notes that start driving behaviour turn into a second, worse
  /// task system inside the first one.
  TextColumn get note => text().nullable()();

  TextColumn get stickerId => text().nullable()();

  IntColumn get estimateMinutes => integer().nullable()();

  TextColumn get projectId => text().nullable()();

  /// ISO weekdays a habit is due, as `1,3,5`. Empty means every day.
  TextColumn get habitWeekdays => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();

  IntColumn get lastCompletedAt => integer().nullable()();

  IntColumn get archivedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The row is `ProjectRow`: the domain type of that name lives in
/// `tally_engine`, and a persistence row is not a domain object. Fourth time
/// this collision has come up, after Treat, SavingsTransfer and Goal.
@DataClassName('ProjectRow')
class Projects extends Table with PortableTable {
  TextColumn get name => text().withLength(min: 1, max: 200)();

  TextColumn get stickerId => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get archivedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Completed focus blocks. **The only thing that earns minutes.**
@DataClassName('SessionRow')
class Sessions extends Table with PortableTable, DayScopedTable {
  TextColumn get taskId => text().nullable()();

  IntColumn get startedAt => integer()();

  IntColumn get endedAt => integer()();

  /// Screen stayed off for the whole block, so the block pays 1.5x.
  BoolColumn get phoneDownVerified =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One day's plan. `today_plan` in the design docs.
@DataClassName('PlanEntryRow')
class PlanEntries extends Table with PortableTable, DayScopedTable {
  TextColumn get taskId => text()();

  /// Explicit, because id order is not an ordering: UUID v7 only sorts across
  /// milliseconds, and two rows added in one tap can share one.
  IntColumn get sortOrder => integer()();

  /// `manual` / `habit` / `suggestion`. Kept because the split of where your
  /// day actually came from is one query and is genuinely interesting.
  TextColumn get source => text()();

  IntColumn get doneAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Which apps the user chose to price.
///
/// Removing an app is **not destructive**: [removedAt] stops future counting
/// from that moment only, and historical spend stays on past statements.
class WatchedApps extends Table with PortableTable {
  TextColumn get packageName => text()();

  TextColumn get label => text()();

  BoolColumn get watching => boolean().withDefault(const Constant(true))();

  IntColumn get addedAt => integer()();

  IntColumn get removedAt => integer().nullable()();

  /// True when the package is absent on this device.
  ///
  /// A restored backup naming apps this phone does not have keeps the row,
  /// greyed, with its history intact. It must never fail the import.
  BoolColumn get notInstalled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// How far usage has been reconciled on **this device**.
///
/// The one table with no [PortableTable] mixin and the one table never
/// exported: it belongs to the old phone. After a restore, reconciliation
/// resumes from the import moment forward and historical `day_ledger` rows come
/// in as frozen history.
class UsageCheckpoints extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get reconciledThrough => integer()();

  IntColumn get recordedAt => integer()();
}

/// What each day closed at. **The single source for every statement.**
///
/// Statements never scan raw events. Derived, and marked as derived (rule 8):
/// on import these are recomputed from sessions and spend rather than trusted.
class DayLedger extends Table with PortableTable, DayScopedTable {
  IntColumn get allowanceGrantedSeconds => integer()();
  IntColumn get allowanceToDebtSeconds => integer()();
  IntColumn get earnedSeconds => integer()();
  IntColumn get earnCappedSeconds => integer()();
  IntColumn get spentSeconds => integer()();
  IntColumn get graceUsedSeconds => integer()();
  IntColumn get unrepayableSeconds => integer()();
  IntColumn get closingBalanceSeconds => integer()();
  IntColumn get closingSavingsSeconds => integer()();
  IntColumn get overflowToSavingsSeconds => integer()();
  IntColumn get treatedSeconds => integer()();
  BoolColumn get solvent => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Billable foreground time, with its real position in the day.
///
/// **The raw input the ledger recomputes from**, already merged so overlapping
/// watched apps were charged once when the row was written.
///
/// Storing a per-day total instead would lose *when* the spend happened, and
/// the ledger is order-sensitive: grace fires on a zero-crossing, so the same
/// minutes spent before or after a focus session produce different balances.
/// A day total would silently place every minute at the day's open, which is
/// both wrong and wrong in the user's favour or against it depending on the
/// day. `ledger_repository_test.dart` has the case that proves it.
@DataClassName('SpendSpanRow')
class SpendSpans extends Table with PortableTable, DayScopedTable {
  TextColumn get packageName => text()();

  IntColumn get startedAt => integer()();

  IntColumn get endedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-app spend for one day. **Derived from [SpendSpans].**
///
/// Exists so the Statement's per-app breakdown is one indexed read rather than
/// a scan, and so that breakdown can be excluded from an export without losing
/// the day's totals: it names your apps and your worst numbers, so it defaults
/// to off in the report builder.
@DataClassName('DaySpendRow')
class DaySpend extends Table with PortableTable, DayScopedTable {
  TextColumn get packageName => text()();

  IntColumn get seconds => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Savings burned on something that is not a screen.
///
/// The row is `TreatRow`, not `Treat`: the domain type of that name lives in
/// `tally_engine`, and a persistence row is not a domain object.
@DataClassName('TreatRow')
class Treats extends Table with PortableTable, DayScopedTable {
  IntColumn get minutesBurned => integer()();

  TextColumn get label => text()();

  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Manual movement between balance and savings.
@DataClassName('SavingsTransferRow')
class SavingsTransfers extends Table with PortableTable, DayScopedTable {
  IntColumn get seconds => integer()();

  /// True moves balance into savings; false is a logged withdrawal covering a
  /// debt. There is no automatic bailout.
  BoolColumn get toSavings => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One stamp per completed task. **Append-only, and never touches the ledger.**
///
/// The second currency, kept separate in the schema rather than by convention.
@DataClassName('StickerStampRow')
class StickerStamps extends Table with PortableTable, DayScopedTable {
  TextColumn get stickerId => text()();

  TextColumn get taskId => text()();

  IntColumn get stampedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Year and life goals.
///
/// Deliberately the least featured thing in the app: no dates, no reminders, no
/// progress bars, and **no path into a day**.
///
/// The row is `GoalRow`: the domain type of that name lives in `tally_ui`, and
/// a persistence row is not a domain object.
@DataClassName('GoalRow')
class Goals extends Table with PortableTable {
  /// `year` or `life`.
  TextColumn get scope => text()();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  TextColumn get note => text().nullable()();

  TextColumn get stickerId => text().nullable()();

  TextColumn get linkedProjectId => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get achievedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Which library suggestions were offered, accepted or dismissed.
class SuggestionHistory extends Table with PortableTable, DayScopedTable {
  TextColumn get itemId => text()();

  /// `offered` / `accepted` / `dismissed`.
  TextColumn get outcome => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Every number that changes the ledger, plus look and behaviour.
///
/// One row per key rather than one wide row, so adding a setting is not a
/// migration and an unknown key from a newer archive can be ignored safely.
class Settings extends Table with PortableTable {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Install identity. Exactly one row.
///
/// Named `AppMeta` rather than `Meta` because drift resolves table classes by
/// name and `Meta` collides with the annotation class in `package:meta`, which
/// fails as an unhelpful "not understood by drift". The SQL table stays `meta`.
@DataClassName('AppMetaRow')
class AppMeta extends Table with PortableTable {
  /// The id every row written on this device is stamped with.
  TextColumn get deviceInstallId => text()();

  IntColumn get installedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
