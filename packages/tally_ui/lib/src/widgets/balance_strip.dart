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
          constraints: const BoxConstraints(minHeight: 56),
          child: Stack(
            children: [
              // The glow: a soft blurred field behind the number, taking the
              // hue of the current state. This is the signature of the app, so
              // it is drawn rather than described.
              Positioned(
                left: 4,
                top: -18,
                child: StateGlow(color: color, width: 170, height: 74),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatMinutes(spendableSeconds),
                      style: text.displayMedium?.copyWith(color: color),
                    ),
                    const SizedBox(width: 6),
                    // The unit label yields first: it is the least informative
                    // thing in the row, and the number and the streak both
                    // carry meaning the user came for.
                    Flexible(
                      child: Text(
                        label,
                        style: text.labelMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
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

/// The blurred state-coloured field behind a number.
///
/// Uses an [ImageFiltered] blur rather than a stack of translucent circles: one
/// composited layer instead of several, which matters on the cheap phones this
/// audience actually owns.
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
