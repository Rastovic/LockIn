import 'package:flutter/material.dart';

import '../theme/state_colors.dart';
import '../theme/tally_theme_data.dart';
import '../widgets/balance_strip.dart';

/// One watched app's share of today.
final class AppSpend {
  const AppSpend({
    required this.packageName,
    required this.label,
    required this.seconds,
    this.notInstalled = false,
  });

  final String packageName;
  final String label;
  final int seconds;

  /// True when the app is absent from this device.
  ///
  /// A restored backup naming apps this phone does not have keeps them, greyed,
  /// with their history intact.
  final bool notInstalled;

  int get minutes => (seconds / 60).round();
}

/// Everything the Balance screen draws.
final class BalanceScreenModel {
  const BalanceScreenModel({
    required this.spendableSeconds,
    required this.earnedSeconds,
    required this.spentSeconds,
    required this.savingsSeconds,
    required this.solvencyStreak,
    required this.bestStreak,
    this.graceRemainingSeconds = 0,
    this.unrepayableSeconds = 0,
    this.spendByApp = const [],
  });

  final int spendableSeconds;
  final int earnedSeconds;
  final int spentSeconds;
  final int savingsSeconds;
  final int solvencyStreak;
  final int bestStreak;

  /// Free minutes left before borrowing starts.
  final int graceRemainingSeconds;

  /// Overspend past the debt floor.
  ///
  /// Recorded for the record but never added to what has to be repaid, so it is
  /// shown separately rather than folded into the balance.
  final int unrepayableSeconds;

  final List<AppSpend> spendByApp;

  int get netSeconds => earnedSeconds - spentSeconds;
}

/// The balance, full screen.
///
/// One tap up from the strip on Today. The number is huge, tabular and tinted
/// by its own state, and it counts down live while a watched app is in the
/// foreground.
class BalanceScreen extends StatelessWidget {
  const BalanceScreen({
    required this.model,
    this.onClose,
    this.onTreat,
    super.key,
  });

  final BalanceScreenModel model;
  final VoidCallback? onClose;

  /// Offered only when there is something saved. A treat button over an empty
  /// pot is an invitation to nothing.
  final VoidCallback? onTreat;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final state = BalanceState.forSeconds(model.spendableSeconds);
    final color = tokens.colorFor(state);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Back to today',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: tokens.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                StateGlow(color: color, width: 320, height: 170, blur: 44),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatMinutes(model.spendableSeconds),
                      style: text.displayLarge?.copyWith(color: color),
                    ),
                    const SizedBox(height: 6),
                    Text(_subtitleFor(state), style: text.bodyMedium),
                  ],
                ),
              ],
            ),
            // Grace is stated only while it is running. A permanent line saying
            // "5 minutes of grace" would read as an allowance rather than as
            // the one-off it is.
            if (state != BalanceState.borrowing &&
                model.spendableSeconds <= 0 &&
                model.graceRemainingSeconds > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${(model.graceRemainingSeconds / 60).ceil()} minutes of grace '
                'left, then you are borrowing',
                style: text.labelMedium?.copyWith(color: tokens.states.low),
                textAlign: TextAlign.center,
              ),
            ],
            if (model.unrepayableSeconds > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Debt stops at −60. Another '
                '${(model.unrepayableSeconds / 60).floor()} minutes went '
                'unrecorded against it.',
                style: text.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _Stat(
                    label: 'EARNED',
                    value: '${(model.earnedSeconds / 60).floor()}',
                    color: tokens.states.solvent,
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    label: 'SPENT',
                    value: '${(model.spentSeconds / 60).floor()}',
                    color: tokens.ink,
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    label: 'SAVED',
                    value: _hours(model.savingsSeconds),
                    color: tokens.states.savings,
                  ),
                ],
              ),
            ),
            if (onTreat != null) ...[
              const SizedBox(height: 14),
              _TreatButton(
                savingsSeconds: model.savingsSeconds,
                onTap: onTreat!,
              ),
            ],
            const SizedBox(height: 16),
            _StreakLine(
              current: model.solvencyStreak,
              best: model.bestStreak,
            ),
            const Spacer(),
            if (model.spendByApp.isNotEmpty)
              _SpendList(spend: model.spendByApp)
            else
              _NoSpendYet(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static String _subtitleFor(BalanceState state) => switch (state) {
        BalanceState.borrowing => 'minutes borrowed',
        _ => 'minutes left today',
      };

  static String _hours(int seconds) {
    final minutes = (seconds / 60).floor();
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label, style: text.labelSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: text.titleLarge?.copyWith(color: color, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// The way out of the app, and the point of saving at all.
class _TreatButton extends StatelessWidget {
  const _TreatButton({required this.savingsSeconds, required this.onTap});

  final int savingsSeconds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        label: 'Treat yourself',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.states.savings),
            ),
            child: Text(
              'Treat yourself',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.states.savings,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakLine extends StatelessWidget {
  const _StreakLine({required this.current, required this.best});

  final int current;
  final int best;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // The streak the app is actually about, so it sits next to the balance.
    // Stated flatly either way: a broken streak is a fact, not a telling-off.
    final line = current > 0
        ? '$current solvent days in a row'
        : 'No streak running';
    return Text(
      best > current ? '$line · best $best' : line,
      style: text.bodyMedium,
    );
  }
}

class _SpendList extends StatelessWidget {
  const _SpendList({required this.spend});

  final List<AppSpend> spend;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final total = spend.fold(0, (sum, app) => sum + app.seconds);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHERE IT WENT', style: text.labelSmall),
          const SizedBox(height: 10),
          for (final app in spend.take(5)) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    app.label,
                    style: text.bodyLarge?.copyWith(
                      color: app.notInstalled ? tokens.inkFaint : tokens.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${app.minutes}m', style: text.labelMedium),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : app.seconds / total,
                minHeight: 4,
                backgroundColor: tokens.surfaceStrong,
                valueColor: AlwaysStoppedAnimation(
                  app.notInstalled ? tokens.inkFaint : tokens.states.borrowing,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _NoSpendYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        // Says nothing congratulatory. A quiet day is a fact about the day, not
        // an achievement to be told about.
        'Nothing spent yet today.',
        style: text.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
