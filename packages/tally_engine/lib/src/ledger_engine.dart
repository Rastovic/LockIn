import 'package:vitals_core/vitals_core.dart';

import 'ledger_result.dart';
import 'session.dart';
import 'settings.dart';
import 'usage.dart';

/// Returns the device's offset from UTC, in minutes, at a given instant.
///
/// A function rather than a number so a DST transition can be modelled: on the
/// last Sunday in March a European local day is 23 hours long, and a ledger
/// that assumes 24 double-counts or loses an hour.
typedef OffsetResolver = int Function(DateTime utcInstant);

/// A fixed offset, for a device that never changes zone.
OffsetResolver fixedOffset(int minutes) => (_) => minutes;

/// The Tally ledger.
///
/// **Derived, never incremental.** Every call recomputes from the inputs, so
/// the same inputs always produce the same numbers. This is the architecture
/// rule that saves the app: an OEM battery manager can kill the foreground
/// service for six hours and the balance is still exactly right the moment the
/// user opens the app. They only missed the nudge.
///
/// Pure Dart by construction. This package cannot import Flutter, which is what
/// makes the iOS port a second [UsageSpan] source rather than a rewrite.
final class LedgerEngine {
  const LedgerEngine({
    this.settings = const LedgerSettings(),
    required this.offsetAt,
  });

  final LedgerSettings settings;
  final OffsetResolver offsetAt;

  /// The day key an instant belongs to.
  String dayKeyAt(DateTime instant) => dayKeyFor(
        instant,
        offsetMinutes: offsetAt(instant),
        dayBoundaryHour: settings.dayBoundaryHour,
      );

  /// The instant a day key opens at.
  ///
  /// Resolved twice: the offset is sampled at a first guess, then re-sampled at
  /// that guess, because the boundary may sit on the far side of a DST change
  /// from the instant being asked about.
  DateTime dayStart(String dayKey) {
    final date = parseDayKey(dayKey);
    if (date == null) {
      throw ArgumentError.value(dayKey, 'dayKey', 'Not a YYYY-MM-DD day key');
    }
    final localOpen = DateTime.utc(
      date.year,
      date.month,
      date.day,
      settings.dayBoundaryHour,
    );
    var guess = localOpen.subtract(Duration(minutes: offsetAt(localOpen)));
    guess = localOpen.subtract(Duration(minutes: offsetAt(guess)));
    return guess;
  }

  /// Recomputes everything between [fromDay] and [toDay] inclusive.
  ///
  /// [openingBalanceSeconds] and [openingSavingsSeconds] are the state at the
  /// start of [fromDay], normally read from the last checkpoint. Passing zero
  /// with the user's first ever day recomputes their entire history.
  LedgerResult compute({
    required String fromDay,
    required String toDay,
    required DateTime now,
    List<FocusSession> sessions = const [],
    List<UsageSpan> spend = const [],
    List<Treat> treats = const [],
    List<SavingsTransfer> transfers = const [],
    int openingBalanceSeconds = 0,
    int openingSavingsSeconds = 0,
    int openingStreak = 0,
    int openingBestStreak = 0,
  }) {
    final dayKeys = dayKeyRange(fromDay, toDay);
    if (dayKeys.isEmpty) {
      throw ArgumentError('toDay ($toDay) is before fromDay ($fromDay)');
    }

    var balance = openingBalanceSeconds;
    var savings = openingSavingsSeconds;
    var streak = openingStreak;
    var bestStreak = openingBestStreak;

    var allowanceRemaining = 0;
    var graceRemaining = settings.graceSeconds;
    var graceArmed = true;

    final rollups = <DayRollup>[];

    for (final dayKey in dayKeys) {
      final start = dayStart(dayKey);
      final end = dayStart(addDays(dayKey, 1));

      // The day ends now if it has not finished yet, so an in-progress day is
      // reported without inventing spend that has not happened.
      final effectiveEnd = end.isAfter(now) ? now : end;

      var allowanceGranted = 0;
      var allowanceToDebt = 0;
      var earned = 0;
      var earnCapped = 0;
      var spent = 0;
      var graceUsed = 0;
      var unrepayable = 0;
      var treated = 0;

      // --- Day boundary: grant the allowance, debt first -------------------
      if (!start.isAfter(now)) {
        allowanceGranted = settings.dailyAllowanceSeconds;
        var grant = allowanceGranted;
        if (balance < 0 && grant > 0) {
          final applied = grant < -balance ? grant : -balance;
          balance += applied;
          grant -= applied;
          allowanceToDebt = applied;
        }
        // Allowance does not roll over: whatever is left of yesterday's is gone.
        allowanceRemaining = grant;
      }

      // Coming out of debt re-arms grace for the next crossing.
      if (balance + allowanceRemaining > 0) {
        graceArmed = true;
        graceRemaining = settings.graceSeconds;
      }

      // --- Build this day's timeline ---------------------------------------
      // Earnings and spend are interleaved in real time rather than netted at
      // the end of the day, because grace fires on a zero-crossing and the
      // order of events decides whether one happened.
      final events = <_LedgerEvent>[];

      for (final session in sessions) {
        if (session.endedAt.isBefore(start) ||
            !session.endedAt.isBefore(effectiveEnd)) {
          continue;
        }
        events.add(_LedgerEvent.earn(session.endedAt, session));
      }

      for (final span in spend) {
        final slice = span.clampTo(start, effectiveEnd);
        if (slice == null) continue;
        events.add(_LedgerEvent.spend(slice.start, slice));
      }

      for (final treat in treats) {
        if (treat.at.isBefore(start) || !treat.at.isBefore(effectiveEnd)) {
          continue;
        }
        events.add(_LedgerEvent.treat(treat.at, treat));
      }

      for (final transfer in transfers) {
        if (transfer.at.isBefore(start) ||
            !transfer.at.isBefore(effectiveEnd)) {
          continue;
        }
        events.add(_LedgerEvent.transfer(transfer.at, transfer));
      }

      events.sort((a, b) => a.at.compareTo(b.at));

      for (final event in events) {
        switch (event) {
          case _EarnEvent(:final session):
            if (session.seconds < settings.minEarnBlockSeconds) continue;
            var credit = (session.seconds * settings.earnRatio).floor();
            if (session.phoneDownVerified) {
              credit = (credit * settings.phoneDownMultiplier).floor();
            }
            final cap = settings.dailyEarnCapSeconds;
            if (cap != null && earned + credit > cap) {
              final allowed = cap - earned;
              earnCapped += credit - (allowed < 0 ? 0 : allowed);
              credit = allowed < 0 ? 0 : allowed;
            }
            if (credit == 0) continue;
            earned += credit;
            // Earnings pay off debt first. You are not solvent until the
            // number is back to zero or above.
            balance += credit;
            if (balance + allowanceRemaining > 0) {
              graceArmed = true;
              graceRemaining = settings.graceSeconds;
            }

          case _SpendEvent(:final span):
            var owed = span.seconds;
            spent += owed;

            final fromAllowance =
                owed < allowanceRemaining ? owed : allowanceRemaining;
            allowanceRemaining -= fromAllowance;
            owed -= fromAllowance;

            if (owed > 0 && balance > 0) {
              final fromBalance = owed < balance ? owed : balance;
              balance -= fromBalance;
              owed -= fromBalance;
            }

            if (owed > 0 && graceArmed && graceRemaining > 0) {
              final free = owed < graceRemaining ? owed : graceRemaining;
              graceRemaining -= free;
              graceUsed += free;
              owed -= free;
              if (graceRemaining == 0) graceArmed = false;
            }

            if (owed > 0) {
              graceArmed = false;
              final floor = settings.debtFloorSeconds;
              final room = balance - floor;
              final repayable = owed < room ? owed : (room < 0 ? 0 : room);
              balance -= repayable;
              unrepayable += owed - repayable;
            }

          case _TreatEvent(:final treat):
            // Burned, not converted. Savings leave the system entirely and
            // cannot return as scroll minutes.
            final burn = treat.seconds < savings ? treat.seconds : savings;
            savings -= burn;
            treated += burn;

          case _TransferEvent(:final transfer):
            if (transfer.toSavings) {
              final move = transfer.seconds < balance && balance > 0
                  ? transfer.seconds
                  : (balance > 0 ? balance : 0);
              balance -= move;
              savings += move;
            } else {
              // Savings may cover a debt, but only by hand, and it is logged as
              // a withdrawal. No automatic bailout.
              final owed = balance < 0 ? -balance : 0;
              var move = transfer.seconds < savings ? transfer.seconds : savings;
              if (move > owed) move = owed;
              savings -= move;
              balance += move;
            }
        }
      }

      // --- Day close --------------------------------------------------------
      final dayIsOver = !end.isAfter(now);
      var overflow = 0;
      if (dayIsOver && balance > settings.rolloverCapSeconds) {
        overflow = balance - settings.rolloverCapSeconds;
        savings += overflow;
        balance = settings.rolloverCapSeconds;
      }

      final solvent = balance >= 0;
      if (dayIsOver) {
        if (solvent) {
          streak += 1;
          if (streak > bestStreak) bestStreak = streak;
        } else {
          streak = 0;
        }
        allowanceRemaining = 0;
      }

      rollups.add(
        DayRollup(
          dayKey: dayKey,
          allowanceGrantedSeconds: allowanceGranted,
          allowanceToDebtSeconds: allowanceToDebt,
          earnedSeconds: earned,
          earnCappedSeconds: earnCapped,
          spentSeconds: spent,
          graceUsedSeconds: graceUsed,
          unrepayableSeconds: unrepayable,
          closingBalanceSeconds: balance,
          closingSavingsSeconds: savings,
          overflowToSavingsSeconds: overflow,
          treatedSeconds: treated,
          solvent: solvent,
        ),
      );
    }

    final graceState = switch (null) {
      _ when balance + allowanceRemaining > 0 => GraceState.solvent,
      _ when graceArmed && graceRemaining > 0 => GraceState.running,
      _ => GraceState.spent,
    };

    return LedgerResult(
      balanceSeconds: balance,
      allowanceRemainingSeconds: allowanceRemaining,
      savingsSeconds: savings,
      graceState: graceState,
      graceRemainingSeconds: graceArmed ? graceRemaining : 0,
      currentSolvencyStreak: streak,
      bestSolvencyStreak: bestStreak,
      days: rollups,
    );
  }
}

sealed class _LedgerEvent {
  const _LedgerEvent(this.at);

  factory _LedgerEvent.earn(DateTime at, FocusSession s) = _EarnEvent;
  factory _LedgerEvent.spend(DateTime at, UsageSpan s) = _SpendEvent;
  factory _LedgerEvent.treat(DateTime at, Treat t) = _TreatEvent;
  factory _LedgerEvent.transfer(DateTime at, SavingsTransfer t) =
      _TransferEvent;

  final DateTime at;
}

final class _EarnEvent extends _LedgerEvent {
  const _EarnEvent(super.at, this.session);
  final FocusSession session;
}

final class _SpendEvent extends _LedgerEvent {
  const _SpendEvent(super.at, this.span);
  final UsageSpan span;
}

final class _TreatEvent extends _LedgerEvent {
  const _TreatEvent(super.at, this.treat);
  final Treat treat;
}

final class _TransferEvent extends _LedgerEvent {
  const _TransferEvent(super.at, this.transfer);
  final SavingsTransfer transfer;
}
