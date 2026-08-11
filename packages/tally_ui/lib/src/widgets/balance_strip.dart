import 'dart:ui';

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
          constraints: const BoxConstraints(minHeight: 60),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Sized to sit **inside** the strip. Letting it escape put a
              // haze outside the widget's own bounds, and a radial gradient
              // needs no room to spare: it already fades to nothing at its
              // edges, so containing it costs no softness.
              // Centred on the whole left cluster - dot, number, unit - whose
              // midpoint sits near x=68. A blur spreads symmetrically but the
              // left half is clipped at the screen edge, so a band positioned
              // by its rectangle alone ends up looking pushed to the right.
              // The offset here is chosen from where the band *reads*, not
              // from where the rectangle starts.
              Positioned(
                left: -18,
                child: StateGlow(
                  color: color,
                  width: 148,
                  height: 66,
                  blur: 20,
                ),
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

/// The state-coloured field behind the balance.
///
/// A blurred rounded rectangle, which reads as a defined band rather than a
/// diffuse haze. That shape was chosen at review over a softer radial falloff.
///
/// It is deliberately **centred on the number**, not anchored to the screen
/// edge. Anchored, the band's mass sits to the right of the figure it belongs
/// to and reads as a smear across the top of the screen rather than as that
/// number's own glow.
class StateGlow extends StatelessWidget {
  const StateGlow({
    required this.color,
    required this.width,
    required this.height,
    this.opacity = 0.5,
    this.blur = 26,
    super.key,
  });

  final Color color;
  final double width;
  final double height;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(height),
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
