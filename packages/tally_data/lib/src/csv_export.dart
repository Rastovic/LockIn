import 'package:drift/drift.dart';

import 'database.dart';

/// The numbers, as a spreadsheet.
///
/// **Deliberately lossy and never re-importable.** This is for reading and for
/// doing your own sums in, and `vitals_archive` is the thing that round-trips.
/// A CSV that half-restores is worse than one that does not restore at all, so
/// the two are kept apart in the code as well as in the UI.
final class CsvExport {
  const CsvExport(this.db);

  final TallyDatabase db;

  /// One row per day, plus a sessions sheet appended below it.
  ///
  /// A single file rather than two, because a user emailing this to themselves
  /// should not have to keep track of a pair.
  Future<String> build({
    required String fromDay,
    required String toDay,
    bool includePerApp = false,
  }) async {
    final buffer = StringBuffer();

    final days = await (db.select(db.dayLedger)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dayKey)]))
        .get();

    buffer.writeln('# lockIn day ledger');
    buffer.writeln(
      'day,allowance_min,earned_min,spent_min,grace_min,'
      'unrepayable_min,closing_balance_min,closing_savings_min,solvent',
    );
    for (final day in days) {
      buffer.writeln(
        [
          day.dayKey,
          _min(day.allowanceGrantedSeconds),
          _min(day.earnedSeconds),
          _min(day.spentSeconds),
          _min(day.graceUsedSeconds),
          _min(day.unrepayableSeconds),
          _min(day.closingBalanceSeconds),
          _min(day.closingSavingsSeconds),
          day.solvent ? 'yes' : 'no',
        ].join(','),
      );
    }

    final sessions = await (db.select(db.sessions)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.startedAt)]))
        .get();
    final tasks = await db.select(db.tasks).get();
    final titles = {for (final task in tasks) task.id: task.title};

    buffer
      ..writeln()
      ..writeln('# Focus sessions')
      ..writeln('day,started,minutes,task,phone_down');
    for (final row in sessions) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(row.startedAt).toLocal();
      buffer.writeln(
        [
          row.dayKey,
          '${started.hour.toString().padLeft(2, '0')}:'
              '${started.minute.toString().padLeft(2, '0')}',
          ((row.endedAt - row.startedAt) / 60000).round(),
          _escape(titles[row.taskId] ?? ''),
          row.phoneDownVerified ? 'yes' : 'no',
        ].join(','),
      );
    }

    // Off by default: it names your apps and your worst numbers, and this file
    // is the one most likely to be shared or left in a downloads folder.
    if (includePerApp) {
      final spend = await (db.select(db.daySpend)
            ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.dayKey)]))
          .get();
      final apps = await db.select(db.watchedApps).get();
      final labels = {for (final app in apps) app.packageName: app.label};

      buffer
        ..writeln()
        ..writeln('# Spend per app')
        ..writeln('day,app,minutes');
      for (final row in spend) {
        buffer.writeln(
          [
            row.dayKey,
            _escape(labels[row.packageName] ?? row.packageName),
            _min(row.seconds),
          ].join(','),
        );
      }
    }

    final treats = await (db.select(db.treats)
          ..where((t) => t.dayKey.isBetweenValues(fromDay, toDay))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    if (treats.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('# Treats')
        ..writeln('day,what,minutes_burned');
      for (final treat in treats) {
        buffer.writeln(
          [treat.dayKey, _escape(treat.label), treat.minutesBurned].join(','),
        );
      }
    }

    return buffer.toString();
  }

  static int _min(int seconds) => (seconds / 60).round();

  /// Quotes anything a spreadsheet would misread.
  ///
  /// Task titles are free text, and a comma in one would silently shift every
  /// column after it.
  static String _escape(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
