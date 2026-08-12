import 'package:flutter/material.dart';

import '../format/durations.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/sticker_chip.dart';

/// One bar in a series.
final class Bar {
  const Bar({required this.label, required this.seconds});

  final String label;
  final int seconds;
}

/// A slice of where focus minutes came from.
final class Slice {
  const Slice({required this.label, required this.seconds, this.stickerId});

  final String label;
  final int seconds;
  final String? stickerId;
}

/// Everything Insights draws.
final class InsightsModel {
  const InsightsModel({
    required this.weeks,
    required this.hourHistogram,
    required this.byCategory,
    required this.phoneDownSeconds,
    required this.longestBlockSeconds,
    required this.dreadCleared,
    required this.emptyDays,
    required this.totalDays,
  });

  /// Focus per week, oldest first.
  final List<Bar> weeks;

  /// 24 buckets, indexed by local hour, of when blocks were started.
  final List<int> hourHistogram;

  final List<Slice> byCategory;

  final int phoneDownSeconds;
  final int longestBlockSeconds;

  /// Long-avoided things finally finished.
  final int dreadCleared;

  /// Days in range with nothing logged at all.
  final int emptyDays;

  final int totalDays;

  bool get hasAnything =>
      weeks.any((w) => w.seconds > 0) || hourHistogram.any((h) => h > 0);

  /// The best week, so the bar chart has something called out rather than
  /// leaving the reader to eyeball it.
  int get bestWeekIndex {
    var best = -1;
    var seconds = 0;
    for (var i = 0; i < weeks.length; i++) {
      if (weeks[i].seconds > seconds) {
        seconds = weeks[i].seconds;
        best = i;
      }
    }
    return best;
  }

  /// The hour blocks are most often started.
  int? get peakHour {
    var peak = -1;
    var count = 0;
    for (var hour = 0; hour < hourHistogram.length; hour++) {
      if (hourHistogram[hour] > count) {
        count = hourHistogram[hour];
        peak = hour;
      }
    }
    return peak < 0 ? null : peak;
  }
}

/// Insights.
///
/// The statement answers "what happened". This answers "what am I actually
/// like" - when you start, what you spend focus on, and how much of it was
/// phone-down.
///
/// Every figure here is **flat**. No targets, no streaks to protect, nothing
/// to fall short of. A screen about your own patterns stops being useful the
/// moment it starts having opinions about them.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({required this.model, this.onBack, super.key});

  final InsightsModel model;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
              child: Row(
                children: [
                  if (onBack != null)
                    Semantics(
                      button: true,
                      label: 'Back',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onBack,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: tokens.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  Text('Insights', style: text.headlineMedium),
                ],
              ),
            ),
            Expanded(
              child: model.hasAnything
                  ? _Body(model: model)
                  : _NothingYet(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.model});

  final InsightsModel model;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('FOCUS PER WEEK', style: text.labelSmall),
        const SizedBox(height: 12),
        _BarSeries(
          bars: model.weeks,
          highlightIndex: model.bestWeekIndex,
        ),
        if (model.bestWeekIndex >= 0) ...[
          const SizedBox(height: 8),
          Text(
            'Your best was ${_hm(model.weeks[model.bestWeekIndex].seconds)} '
            'in ${model.weeks[model.bestWeekIndex].label}.',
            style: text.bodyMedium,
          ),
        ],
        const SizedBox(height: 28),
        Text('WHEN YOU START', style: text.labelSmall),
        const SizedBox(height: 12),
        _HourHistogram(counts: model.hourHistogram),
        if (model.peakHour case final hour?) ...[
          const SizedBox(height: 8),
          Text(
            // Stated as an observation, never as advice. The app does not know
            // what a good hour is for this person.
            'You start most often around ${_hour(hour)}.',
            style: text.bodyMedium,
          ),
        ],
        if (model.byCategory.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('WHAT YOU FOCUS ON', style: text.labelSmall),
          const SizedBox(height: 12),
          for (final slice in model.byCategory.take(6))
            _SliceLine(
              slice: slice,
              total: model.byCategory.fold(0, (a, s) => a + s.seconds),
            ),
        ],
        const SizedBox(height: 28),
        Text('FLATLY', style: text.labelSmall),
        const SizedBox(height: 12),
        _Fact(
          label: 'Focused with the phone down',
          value: _hm(model.phoneDownSeconds),
        ),
        _Fact(
          label: 'Longest single block',
          value: _hm(model.longestBlockSeconds),
        ),
        _Fact(
          label: 'Long-avoided things finished',
          value: '${model.dreadCleared}',
        ),
        _Fact(
          // Stated without comment. Days with nothing logged are a fact about
          // the record, not a failure, and plenty of them are days that simply
          // did not need the app.
          label: 'Days with nothing logged',
          value: '${model.emptyDays} of ${model.totalDays}',
        ),
      ],
    );
  }

  static String _hm(int seconds) {
    final minutes = wholeMinutes(seconds);
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  static String _hour(int hour) {
    if (hour == 0) return 'midnight';
    if (hour == 12) return 'midday';
    return hour < 12 ? '${hour}am' : '${hour - 12}pm';
  }
}

/// A bar series, per section 4 of the design system.
///
/// 8pt wide, radius 4, accent for the called-out bar and faint ink for the
/// rest. No axes and no grid: the numbers that matter are stated in words
/// underneath instead.
class _BarSeries extends StatelessWidget {
  const _BarSeries({required this.bars, required this.highlightIndex});

  final List<Bar> bars;
  final int highlightIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final peak = bars.fold(0, (m, b) => b.seconds > m ? b.seconds : m);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: peak == 0
                        ? 2
                        : (8 + 90 * (bars[i].seconds / peak)).toDouble(),
                    decoration: BoxDecoration(
                      color: i == highlightIndex
                          ? tokens.states.solvent
                          : tokens.inkFaint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bars[i].label,
                    style: text.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ],
              ),
            ),
            if (i != bars.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// When blocks get started, by hour.
///
/// Twenty-four bars is too many to label, so only the anchors are named. The
/// shape is the point, not the exact hour.
class _HourHistogram extends StatelessWidget {
  const _HourHistogram({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final peak = counts.fold(0, (m, c) => c > m ? c : m);

    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var hour = 0; hour < counts.length; hour++) ...[
                Expanded(
                  child: Semantics(
                    label: '${counts[hour]} blocks started at $hour',
                    excludeSemantics: true,
                    child: Container(
                      height: peak == 0
                          ? 2
                          : (3 + 62 * (counts[hour] / peak)).toDouble(),
                      decoration: BoxDecoration(
                        color: counts[hour] == 0
                            ? tokens.surfaceStrong
                            : tokens.states.solvent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                if (hour != counts.length - 1) const SizedBox(width: 2),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('12am', style: text.labelSmall),
            Text('6am', style: text.labelSmall),
            Text('midday', style: text.labelSmall),
            Text('6pm', style: text.labelSmall),
            Text('11pm', style: text.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _SliceLine extends StatelessWidget {
  const _SliceLine({required this.slice, required this.total});

  final Slice slice;
  final int total;

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
              if (slice.stickerId != null) ...[
                StickerChip(stickerId: slice.stickerId!, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  slice.label,
                  style: text.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${wholeMinutes(slice.seconds)}m',
                style: text.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (slice.seconds / total).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: tokens.surfaceStrong,
              valueColor: AlwaysStoppedAnimation(tokens.states.solvent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(value, style: text.bodyLarge),
        ],
      ),
    );
  }
}

class _NothingYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Text(
          'Nothing to show yet. A few focus sessions and this starts to say '
          'something about when you actually work.',
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
