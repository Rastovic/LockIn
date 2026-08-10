/// What one day closed at.
///
/// `day_ledger` in the schema, and the single source for every statement.
/// Statements never scan raw events.
final class DayRollup {
  const DayRollup({
    required this.dayKey,
    required this.allowanceGrantedSeconds,
    required this.allowanceToDebtSeconds,
    required this.earnedSeconds,
    required this.earnCappedSeconds,
    required this.spentSeconds,
    required this.graceUsedSeconds,
    required this.unrepayableSeconds,
    required this.closingBalanceSeconds,
    required this.closingSavingsSeconds,
    required this.overflowToSavingsSeconds,
    required this.treatedSeconds,
    required this.solvent,
  });

  final String dayKey;

  /// Allowance granted at this day's boundary.
  final int allowanceGrantedSeconds;

  /// The part of that allowance that went to clearing debt rather than to
  /// spendable balance.
  final int allowanceToDebtSeconds;

  /// Credited after the ratio, the phone-down bonus and the daily cap.
  final int earnedSeconds;

  /// Earned but refused by the daily cap. Shown so the cap is visible rather
  /// than mysterious.
  final int earnCappedSeconds;

  /// Billable foreground seconds on watched apps.
  final int spentSeconds;

  /// Of [spentSeconds], the part that was free because grace was running.
  final int graceUsedSeconds;

  /// Real overspend below the debt floor.
  ///
  /// Recorded for the statement but never added to what the user must repay.
  final int unrepayableSeconds;

  /// The repayable balance at day close. Negative is debt.
  final int closingBalanceSeconds;

  final int closingSavingsSeconds;

  /// Earned credit above the rollover cap, moved to savings at day close.
  final int overflowToSavingsSeconds;

  /// Savings burned on a treat during this day.
  final int treatedSeconds;

  /// A day is solvent if it ends at zero or above. This is the streak the app
  /// is actually about.
  final bool solvent;

  int get netSeconds => earnedSeconds - spentSeconds;

  @override
  String toString() => 'DayRollup($dayKey, closing: ${closingBalanceSeconds}s, '
      'solvent: $solvent)';
}

/// Where the user stands right now against the grace rule.
enum GraceState {
  /// Balance is above zero. Grace is armed for the next crossing.
  solvent,

  /// Balance has reached zero and the free minutes are running.
  running,

  /// Grace for this crossing is spent. Further minutes cost.
  spent,
}

/// The whole answer, recomputed from inputs every time.
final class LedgerResult {
  const LedgerResult({
    required this.balanceSeconds,
    required this.allowanceRemainingSeconds,
    required this.savingsSeconds,
    required this.graceState,
    required this.graceRemainingSeconds,
    required this.currentSolvencyStreak,
    required this.bestSolvencyStreak,
    required this.days,
  });

  /// Earned credit, carried across days. Negative is debt, floored by
  /// [LedgerSettings.debtFloorMinutes].
  final int balanceSeconds;

  /// Today's allowance not yet spent. Expires at the day boundary and never
  /// rolls over.
  final int allowanceRemainingSeconds;

  final int savingsSeconds;

  final GraceState graceState;
  final int graceRemainingSeconds;

  final int currentSolvencyStreak;
  final int bestSolvencyStreak;

  /// One entry per day in the requested range, ascending, with no gaps.
  final List<DayRollup> days;

  /// The single number on the Balance screen.
  ///
  /// Allowance and earned credit are one number to the user; they are separate
  /// internally only because allowance expires and earned credit rolls over.
  int get spendableSeconds => balanceSeconds < 0
      ? balanceSeconds
      : balanceSeconds + allowanceRemainingSeconds;

  int get spendableMinutes => (spendableSeconds / 60).floor();

  bool get inDebt => balanceSeconds < 0;

  @override
  String toString() => 'LedgerResult(${spendableMinutes}m, '
      'savings: ${(savingsSeconds / 60).floor()}m, '
      'streak: $currentSolvencyStreak)';
}
