import 'package:flutter/widgets.dart';

/// What the balance is doing right now.
///
/// **State is the primary signal in this app**, which is why it is an enum with
/// a colour rather than a colour chosen at each call site. The screen should
/// read before a single word does.
enum BalanceState {
  /// Ten minutes or more. The resting state, and the one you should mostly see.
  solvent,

  /// Under ten minutes.
  low,

  /// Below zero.
  borrowing,

  /// Savings. Never spendable on scrolling, so it is never the balance state -
  /// it appears only where savings are shown.
  savings;

  /// The state for a spendable balance, in seconds.
  ///
  /// Settled decision 6: mint at 10 minutes or more, amber under 10, coral once
  /// negative.
  static BalanceState forSeconds(int seconds) {
    if (seconds < 0) return BalanceState.borrowing;
    if (seconds < 10 * 60) return BalanceState.low;
    return BalanceState.solvent;
  }
}

/// The four colours a theme must supply.
///
/// **The rule that keeps three themes honest:** a theme may change every
/// surface, but it must supply its own four, they must stay mutually
/// distinguishable, and they must pass contrast on that theme's own ground.
/// That is why Blush's borrowing is a deep crimson and not another pink.
@immutable
final class StateColors {
  const StateColors({
    required this.solvent,
    required this.low,
    required this.borrowing,
    required this.savings,
    this.borrowingGlow,
  });

  final Color solvent;
  final Color low;
  final Color borrowing;
  final Color savings;

  /// What the blurred field behind the balance is painted in when borrowing.
  ///
  /// Null everywhere it is not needed, and the state colour is used instead.
  ///
  /// It exists because a colour graded for **text** makes a bad **field**. On a
  /// light ground the borrowing red is dark and low in saturation so it can
  /// carry 4.5:1 as a number; blurred at half alpha across near-white it
  /// composites to a muddy brick smear rather than reading as that number's own
  /// light. A lighter, more saturated tint of the same family composites to a
  /// clear colour and, measured against the solvent glow, separates further
  /// than the dark one did - so this is not a trade of clarity for prettiness.
  ///
  /// The number itself never uses this. Contrast and the distinguishability
  /// rule still bind the state colours, and they are what carries the meaning.
  final Color? borrowingGlow;

  /// The colour for the blurred field behind the balance.
  Color glowFor(BalanceState state) => state == BalanceState.borrowing
      ? (borrowingGlow ?? borrowing)
      : of(state);

  Color of(BalanceState state) => switch (state) {
        BalanceState.solvent => solvent,
        BalanceState.low => low,
        BalanceState.borrowing => borrowing,
        BalanceState.savings => savings,
      };

  List<Color> get all => [solvent, low, borrowing, savings];
}
