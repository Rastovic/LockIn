/// Every number that changes the ledger, in one place.
///
/// Tally's plan puts all of these on a single "Watched apps and rules" screen
/// deliberately: one screen for the maths, so there is never a second place to
/// look for it.
///
/// Durations are whole seconds. No doubles anywhere in a ledger, ever
/// (`DATA-PORTABILITY.md` rule 7). [earnRatio] and [phoneDownMultiplier] are the
/// only fractional inputs, and both are applied with integer truncation.
final class LedgerSettings {
  const LedgerSettings({
    this.earnRatio = 1.0,
    this.dailyEarnCapMinutes = 90,
    this.dailyAllowanceMinutes = 0,
    this.rolloverCapMinutes = 60,
    this.graceMinutes = 0,
    this.debtFloorMinutes = 60,
    this.minEarnBlockMinutes = 5,
    this.phoneDownMultiplier = 1.5,
    this.dayBoundaryHour = 4,
  })  : assert(earnRatio > 0, 'A zero ratio makes focusing pointless'),
        assert(dailyAllowanceMinutes >= 0),
        assert(rolloverCapMinutes >= 0),
        assert(graceMinutes >= 0),
        assert(debtFloorMinutes >= 0, 'Expressed as a positive magnitude'),
        assert(minEarnBlockMinutes >= 0),
        assert(phoneDownMultiplier >= 1.0);

  /// Minutes earned per minute focused. 2.0 for the strict, 0.5 for the gentle.
  final double earnRatio;

  /// Most minutes a single day can earn, or null for no cap.
  ///
  /// Exists so one four-hour study day does not buy a whole weekend of
  /// scrolling.
  final int? dailyEarnCapMinutes;

  /// Free minutes granted at each day boundary. May be zero.
  ///
  /// Does not roll over. Day one must not be a brick wall.
  /// Free minutes granted at the day boundary. **Zero by default.**
  ///
  /// A non-zero default hands out the app's own currency before the user has
  /// done anything, which makes the first day a smaller version of the problem
  /// rather than the start of the fix. Starting at zero means every minute of
  /// scrolling is one that was focused for, from the first day, and the number
  /// on the strip means the same thing on day one as it does on day ninety.
  ///
  /// Still settable: someone who wants a floor under the day can pick one.
  final int dailyAllowanceMinutes;

  /// Most earned credit that survives a day boundary. The overflow becomes
  /// savings rather than evaporating.
  final int rolloverCapMinutes;

  /// Free minutes after the balance first reaches zero. **Zero by default.**
  ///
  /// Once per zero-crossing, not once per session.
  ///
  /// Turned off. Grace was five free minutes handed out the moment the balance
  /// hit zero, which made zero mean two different things depending on whether it
  /// had been crossed yet this stretch - and the one number the whole app rests
  /// on cannot be conditional. It also arrived exactly when the user was being
  /// told to stop, which is the worst moment to say "well, a bit more".
  ///
  /// The mechanism is still here and still correct, because the debt floor and
  /// the statement both reason about it, and a stored ledger recomputed under a
  /// build that had never heard of grace would disagree with its own history.
  /// At zero it simply never fires.
  final int graceMinutes;

  /// How far the repayable balance may go negative, as a positive magnitude.
  ///
  /// Past this the real minutes are still recorded for the statement, but the
  /// number the user has to repay stops growing: a debt nobody believes they
  /// can repay gets the app deleted.
  final int debtFloorMinutes;

  /// Shortest focus block that earns anything, so the timer cannot be farmed in
  /// 30 second bursts.
  final int minEarnBlockMinutes;

  /// Paid on a block where the screen stayed off throughout.
  final double phoneDownMultiplier;

  /// Local hour a new day starts. 4 means 03:59 still closes yesterday.
  final int dayBoundaryHour;

  int get dailyAllowanceSeconds => dailyAllowanceMinutes * 60;
  int get rolloverCapSeconds => rolloverCapMinutes * 60;
  int get graceSeconds => graceMinutes * 60;
  int get debtFloorSeconds => -debtFloorMinutes * 60;
  int get minEarnBlockSeconds => minEarnBlockMinutes * 60;
  int? get dailyEarnCapSeconds =>
      dailyEarnCapMinutes == null ? null : dailyEarnCapMinutes! * 60;

  LedgerSettings copyWith({
    double? earnRatio,
    int? dailyEarnCapMinutes,
    bool clearEarnCap = false,
    int? dailyAllowanceMinutes,
    int? rolloverCapMinutes,
    int? graceMinutes,
    int? debtFloorMinutes,
    int? minEarnBlockMinutes,
    double? phoneDownMultiplier,
    int? dayBoundaryHour,
  }) =>
      LedgerSettings(
        earnRatio: earnRatio ?? this.earnRatio,
        dailyEarnCapMinutes: clearEarnCap
            ? null
            : (dailyEarnCapMinutes ?? this.dailyEarnCapMinutes),
        dailyAllowanceMinutes:
            dailyAllowanceMinutes ?? this.dailyAllowanceMinutes,
        rolloverCapMinutes: rolloverCapMinutes ?? this.rolloverCapMinutes,
        graceMinutes: graceMinutes ?? this.graceMinutes,
        debtFloorMinutes: debtFloorMinutes ?? this.debtFloorMinutes,
        minEarnBlockMinutes: minEarnBlockMinutes ?? this.minEarnBlockMinutes,
        phoneDownMultiplier: phoneDownMultiplier ?? this.phoneDownMultiplier,
        dayBoundaryHour: dayBoundaryHour ?? this.dayBoundaryHour,
      );
}
