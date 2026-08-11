import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/sticker_chip.dart';

/// What a statement covers.
enum StatementPeriod {
  day('Day', 1),
  week('Week', 7),
  month('Month', 30),
  year('Year', 365);

  const StatementPeriod(this.label, this.days);

  final String label;
  final int days;
}

/// One task's contribution to what was earned.
final class TaskEarn {
  const TaskEarn({
    required this.title,
    required this.seconds,
    this.stickerId,
  });

  final String title;
  final int seconds;
  final String? stickerId;
}

/// A treat taken, with what it was.
final class TreatTaken {
  const TreatTaken({
    required this.label,
    required this.minutesBurned,
    required this.dayKey,
  });

  final String label;
  final int minutesBurned;
  final String dayKey;
}

/// Everything the statement draws, computed from stored day rollups.
///
/// **Never from raw events.** The rollups are the single source for every
/// statement, which is what keeps a 90 day view fast on a phone.
final class StatementModel {
  const StatementModel({
    required this.period,
    required this.days,
    required this.previousEarnedSeconds,
    required this.previousSpentSeconds,
    this.spendByApp = const [],
    this.earnByTask = const [],
    this.treats = const [],
    this.savingsSeconds = 0,
  });

  final StatementPeriod period;

  /// Ascending, one per day, with no gaps.
  final List<DayRollup> days;

  final int previousEarnedSeconds;
  final int previousSpentSeconds;

  final List<AppSpendLine> spendByApp;
  final List<TaskEarn> earnByTask;
  final List<TreatTaken> treats;
  final int savingsSeconds;

  int get earnedSeconds => days.fold(0, (a, d) => a + d.earnedSeconds);
  int get spentSeconds => days.fold(0, (a, d) => a + d.spentSeconds);
  int get netSeconds => earnedSeconds - spentSeconds;

  int get solventDays => days.where((d) => d.solvent).length;

  /// The day that went furthest under.
  DayRollup? get worstDay {
    DayRollup? worst;
    for (final day in days) {
      if (day.closingBalanceSeconds >= 0) continue;
      if (worst == null ||
          day.closingBalanceSeconds < worst.closingBalanceSeconds) {
        worst = day;
      }
    }
    return worst;
  }

  /// Longest run of solvent days inside the period.
  int get longestSolventRun {
    var best = 0;
    var run = 0;
    for (final day in days) {
      run = day.solvent ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

  int get earnedChange => earnedSeconds - previousEarnedSeconds;
  int get spentChange => spentSeconds - previousSpentSeconds;

  bool get hasAnything => earnedSeconds > 0 || spentSeconds > 0;
}

/// One app's spend over the period.
final class AppSpendLine {
  const AppSpendLine({
    required this.label,
    required this.seconds,
    this.notInstalled = false,
  });

  final String label;
  final int seconds;
  final bool notInstalled;
}

/// The statement.
///
/// Reads only from stored day rollups, so a long period is a handful of indexed
/// rows rather than a scan. Every figure has a comparison where one exists,
/// because a number with nothing to compare it to is trivia.
class StatementScreen extends StatelessWidget {
  const StatementScreen({
    required this.model,
    this.onPeriod,
    this.showPerApp = true,
    super.key,
  });

  final StatementModel model;
  final ValueChanged<StatementPeriod>? onPeriod;

  /// Off by default in the report builder, since it names your apps and your
  /// worst numbers. On here, where only you are looking.
  final bool showPerApp;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Text('Statement', style: text.headlineMedium),
                  const Spacer(),
                  Text(
                    '${model.solventDays} of ${model.days.length} solvent',
                    style: text.labelMedium,
                  ),
                ],
              ),
            ),
            _PeriodSwitcher(selected: model.period, onPick: onPeriod),
            Expanded(
              child: model.hasAnything
                  ? _Body(model: model, showPerApp: showPerApp)
                  : _NothingYet(period: model.period),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.model, required this.showPerApp});

  final StatementModel model;
  final bool showPerApp;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            _Figure(
              label: 'EARNED',
              seconds: model.earnedSeconds,
              change: model.earnedChange,
              color: tokens.states.solvent,
              // More earned is better, so an increase reads as good.
              upIsGood: true,
            ),
            const SizedBox(width: 10),
            _Figure(
              label: 'SPENT',
              seconds: model.spentSeconds,
              change: model.spentChange,
              color: tokens.ink,
              upIsGood: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _NetLine(seconds: model.netSeconds),
        const SizedBox(height: 24),
        Text('EACH DAY', style: text.labelSmall),
        const SizedBox(height: 10),
        _Heatmap(days: model.days),
        const SizedBox(height: 22),
        if (model.longestSolventRun > 0)
          _Fact(
            label: 'Longest solvent run',
            value: '${model.longestSolventRun} days',
          ),
        if (model.worstDay case final worst?)
          _Fact(
            label: 'Furthest under',
            value: '${(worst.closingBalanceSeconds / 60).ceil()} min '
                'on ${_shortDay(worst.dayKey)}',
            color: tokens.states.borrowing,
          ),
        if (showPerApp && model.spendByApp.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('WHERE IT WENT', style: text.labelSmall),
          const SizedBox(height: 10),
          for (final app in model.spendByApp.take(6))
            _BarLine(
              label: app.label,
              seconds: app.seconds,
              total: model.spentSeconds,
              color: tokens.states.borrowing,
              muted: app.notInstalled,
            ),
        ],
        if (model.earnByTask.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('WHERE IT CAME FROM', style: text.labelSmall),
          const SizedBox(height: 10),
          for (final task in model.earnByTask.take(6))
            _BarLine(
              label: task.title,
              seconds: task.seconds,
              total: model.earnedSeconds,
              color: tokens.states.solvent,
              stickerId: task.stickerId,
            ),
        ],
        const SizedBox(height: 24),
        _SavingsBlock(
          savingsSeconds: model.savingsSeconds,
          treats: model.treats,
        ),
      ],
    );
  }

  static String _shortDay(String dayKey) {
    final parts = dayKey.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}' : dayKey;
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.selected, required this.onPick});

  final StatementPeriod selected;
  final ValueChanged<StatementPeriod>? onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final period in StatementPeriod.values) ...[
            Expanded(
              child: Semantics(
                button: true,
                selected: period == selected,
                label: period.label,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onPick?.call(period),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: period == selected
                          ? tokens.states.solvent
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      period.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: period == selected
                                ? tokens.bg
                                : tokens.inkMuted,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            if (period != StatementPeriod.values.last)
              const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.seconds,
    required this.change,
    required this.color,
    required this.upIsGood,
  });

  final String label;
  final int seconds;
  final int change;
  final Color color;
  final bool upIsGood;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final minutes = (seconds / 60).floor();
    final changeMinutes = (change / 60).round();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.labelSmall),
            const SizedBox(height: 4),
            Text(
              _hm(minutes),
              style: text.titleLarge?.copyWith(color: color, fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(
              // A number with nothing to compare it to is trivia, so the
              // change is always stated. Neutral when there is no previous
              // period to compare against.
              changeMinutes == 0
                  ? 'same as before'
                  : '${changeMinutes > 0 ? '+' : ''}$changeMinutes vs before',
              style: text.labelMedium?.copyWith(
                color: changeMinutes == 0
                    ? tokens.inkFaint
                    : (changeMinutes > 0) == upIsGood
                        ? tokens.states.solvent
                        : tokens.states.low,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hm(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _NetLine extends StatelessWidget {
  const _NetLine({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final minutes = (seconds / 60).floor();
    final positive = minutes >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              positive
                  ? 'You earned more than you spent'
                  : 'You spent more than you earned',
              style: text.bodyLarge,
            ),
          ),
          Text(
            '${positive ? '+' : ''}${minutes}m',
            style: text.titleLarge?.copyWith(
              color: positive ? tokens.states.solvent : tokens.states.borrowing,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minutes per day, one cell each.
///
/// Solvent days take the mint, days that closed under take the coral. Intensity
/// is how much was spent, so a heavy day reads as heavy whichever side of zero
/// it ended on.
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});

  final List<DayRollup> days;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final peak = days.fold(0, (m, d) => d.spentSeconds > m ? d.spentSeconds : m);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final day in days)
          Semantics(
            label: '${day.dayKey}: '
                '${(day.spentSeconds / 60).round()} minutes spent',
            excludeSemantics: true,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: day.spentSeconds == 0
                    ? tokens.surfaceStrong
                    : (day.solvent
                            ? tokens.states.solvent
                            : tokens.states.borrowing)
                        .withValues(
                        alpha: peak == 0
                            ? 0.3
                            : 0.25 + 0.75 * (day.spentSeconds / peak),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BarLine extends StatelessWidget {
  const _BarLine({
    required this.label,
    required this.seconds,
    required this.total,
    required this.color,
    this.stickerId,
    this.muted = false,
  });

  final String label;
  final int seconds;
  final int total;
  final Color color;
  final String? stickerId;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (stickerId != null) ...[
                StickerChip(stickerId: stickerId!, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(
                    color: muted ? tokens.inkFaint : tokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${(seconds / 60).round()}m', style: text.labelMedium),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (seconds / total).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: tokens.surfaceStrong,
              valueColor: AlwaysStoppedAnimation(
                muted ? tokens.inkFaint : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(
            value,
            style: text.bodyLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Savings, treats, and the standing tip.
///
/// The counterweight to the whole app. Without it the statement is only a
/// record of what you spent, and the app is only a scold.
class _SavingsBlock extends StatelessWidget {
  const _SavingsBlock({required this.savingsSeconds, required this.treats});

  final int savingsSeconds;
  final List<TreatTaken> treats;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final minutes = (savingsSeconds / 60).floor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SAVED', style: text.labelSmall),
              const Spacer(),
              Text(
                minutes < 60
                    ? '${minutes}m'
                    : '${minutes ~/ 60}h ${minutes % 60}m',
                style: text.titleLarge?.copyWith(
                  color: tokens.states.savings,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          if (treats.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final treat in treats)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(treat.label, style: text.bodyMedium),
                    ),
                    Text(
                      '${treat.minutesBurned}m',
                      style: text.labelMedium,
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Text(
            // The standing tip. It never changes and it never fires as a
            // notification: it is a line on a page, not a nag.
            'Being honest with yourself matters, and so does paying yourself.',
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _NothingYet extends StatelessWidget {
  const _NothingYet({required this.period});

  final StatementPeriod period;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Text(
          // States the fact and what would change it. Does not congratulate a
          // blank week.
          period == StatementPeriod.day
              ? 'Nothing recorded today yet. Focus on something, or open one '
                  'of your watched apps, and this fills in.'
              : 'Nothing recorded in this period yet.',
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
