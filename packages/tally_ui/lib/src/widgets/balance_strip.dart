import 'package:flutter/material.dart';

import '../theme/state_colors.dart';
import '../theme/tally_theme_data.dart';

/// Formats a signed minute count the way the app always shows it.
///
/// **Floors towards negative infinity, never towards zero**, so 90 seconds of
/// debt reads as −2 and not −1. Rounding a debt towards zero flatters the
/// number, which is the one thing this app must never do.
String formatMinutes(int seconds) {
  final minutes = (seconds / 60).floor();
  return minutes < 0 ? '−${minutes.abs()}' : '$minutes';
}

/// The balance, as a strip across the top of Today.
///
/// **Settled decision 17: 22px, reviewed and kept.** The state-tinted glow does
/// the reading, not the type size, and the live countdown adds motion a static
/// mock could not show. One tap opens the full ticker.
class BalanceStrip extends StatelessWidget {
  const BalanceStrip({
    required this.spendableSeconds,
    required this.solvencyStreak,
    this.onTap,
    super.key,
  });

  final int spendableSeconds;

  /// Days ending at zero or above, in a row. The streak the app is actually
  /// about, so it sits next to the balance.
  final int solvencyStreak;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = BalanceState.forSeconds(spendableSeconds);
    final color = tokens.colorFor(state);
    final text = Theme.of(context).textTheme;

    final label = switch (state) {
      BalanceState.borrowing => 'borrowing',
      BalanceState.low => 'min left',
      _ => 'min left',
    };

    return Semantics(
      button: onTap != null,
      label: switch (state) {
        BalanceState.borrowing =>
          'Borrowing ${formatMinutes(spendableSeconds).replaceAll('−', '')} '
              'minutes. Solvency streak broken.',
        _ => '${formatMinutes(spendableSeconds)} minutes left. '
            '$solvencyStreak solvent days.',
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          // Grows rather than overflows when the user raises text size. The
          // design system requires Dynamic Type to 200%, and a fixed height
          // here clipped the streak pill long before that.
          constraints: const BoxConstraints(minHeight: 64),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Sized to sit **inside** the strip. Letting it escape put a
              // haze outside the widget's own bounds, and a radial gradient
              // needs no room to spare: it already fades to nothing at its
              // edges, so containing it costs no softness.
              Positioned(
                left: -56,
                child: StateGlow(color: color, width: 230, height: 64),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    // The left cluster stays tight. Grouping it means the
                    // spacing between the dot, the number and the unit is
                    // fixed, and only the gap before the pill absorbs the
                    // leftover width.
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            formatMinutes(spendableSeconds),
                            style: text.displayMedium?.copyWith(color: color),
                          ),
                          const SizedBox(width: 5),
                          // Yields first when space runs short: it is the
                          // least informative thing in the row.
                          Flexible(
                            child: Text(
                              label,
                              style: text.labelMedium,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _StreakPill(
                        streak: solvencyStreak,
                        broken: state == BalanceState.borrowing,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The soft state-coloured halo behind the balance.
///
/// A circular gradient stretched horizontally, rather than a blurred rectangle.
///
/// Two things forced this shape. A blur needs its own composited layer every
/// frame and turns into a hard-edged box the moment anything clips it, which is
/// what happened inside the Stack. And `RadialGradient.radius` is a fraction of
/// the box's **shortest** side, so asking for a wide band directly gives a small
/// circle instead.
///
/// Drawing a true circle that fades to nothing at its own edge, then scaling it
/// on one axis, gives a wide band that is soft on every side and needs no room
/// outside the strip.
class StateGlow extends StatelessWidget {
  const StateGlow({
    required this.color,
    required this.width,
    required this.height,
    this.opacity = 0.5,
    super.key,
  });

  final Color color;
  final double width;
  final double height;

  /// Peak alpha at the centre. This is a tint that tells you the state before
  /// you read the number, not a light source.
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(width / height, 1, 1),
              child: Container(
                width: height,
                height: height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: opacity),
                      color.withValues(alpha: opacity * 0.5),
                      color.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak, required this.broken});

  final int streak;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        // Plain and factual either way. A broken streak is stated, never
        // scolded.
        broken ? 'streak broken' : '$streak solvent days',
        style: Theme.of(context).textTheme.labelMedium,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
