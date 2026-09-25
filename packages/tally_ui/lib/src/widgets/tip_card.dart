import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';

/// Where a tip can appear.
enum TipSurface { today, tasks, stats, settings, focus, balance }

/// A one-time explanation, shown where the thing it explains lives.
///
/// **Taught in place, once.** First run shows only the loop; everything else
/// is explained the first time its screen opens, when the person is looking at
/// it, and never again after "Got it". The full list is the tour in Settings.
enum Tip {
  today(
    'This is today',
    'Tick a task to earn its estimate, or press play to focus on it. Drag a '
        'row to move it.',
  ),
  tasks(
    'Your list',
    'Everything written down lives here. A task joins a day when you add it '
        'from Today, or by itself if it repeats.',
  ),
  stats(
    'Three ways to look back',
    'Statement is what happened, Insights is what you are like, Stickers is '
        'what you collected.',
  ),
  settings(
    'Your rules',
    'The watched apps, the rate and the allowance live here. Everything '
        'LockIn can do is listed under Elsewhere.',
  ),
  focus(
    'The clock is real time',
    'It keeps counting with the screen off. Finish the block and its task is '
        'ticked.',
  ),
  balance(
    'Where the minutes are',
    'Minutes above the rollover cap move to savings at the end of the day. '
        'Savings buy treats, never scrolling.',
  ),

  /// Held back a couple of days: on day one a home screen widget is one more
  /// thing to set up, after a few days it is a shortcut to something known.
  widget(
    'LockIn on the home screen',
    'Long-press the home screen, open Widgets and find LockIn: today’s list, '
        'or a one-line capture.',
  ),

  /// Held back longer, and only offered while blocking is off. It reverses
  /// the app's default, so it comes once the counting is familiar.
  blocking(
    'A harder stop, if you want one',
    'Settings can cover a watched app once the minutes run out. It stays off '
        'unless you turn it on.',
  );

  const Tip(this.title, this.body);

  final String title;
  final String body;

  /// Days since first run before [widget] is offered.
  static const widgetAfterDays = 2;

  /// Days since first run before [blocking] is offered.
  static const blockingAfterDays = 4;
}

/// The tip to show on [surface], or null.
///
/// One at a time, and the screen's own tip first: two cards stacked is a
/// manual, not a tip. The held-back tips only appear on Today, the screen
/// opened most, and only after the screen's own tip has been dismissed.
Tip? pickTip({
  required TipSurface surface,
  required Set<Tip> seen,
  required int daysSinceFirstRun,
  required bool blockingOff,
}) {
  final own = switch (surface) {
    TipSurface.today => Tip.today,
    TipSurface.tasks => Tip.tasks,
    TipSurface.stats => Tip.stats,
    TipSurface.settings => Tip.settings,
    TipSurface.focus => Tip.focus,
    TipSurface.balance => Tip.balance,
  };
  if (!seen.contains(own)) return own;
  if (surface != TipSurface.today) return null;

  if (daysSinceFirstRun >= Tip.widgetAfterDays && !seen.contains(Tip.widget)) {
    return Tip.widget;
  }
  if (blockingOff &&
      daysSinceFirstRun >= Tip.blockingAfterDays &&
      !seen.contains(Tip.blocking)) {
    return Tip.blocking;
  }
  return null;
}

/// A tip, with the one button that retires it.
class TipCard extends StatelessWidget {
  const TipCard({required this.tip, required this.onDismiss, super.key});

  final Tip tip;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: tokens.surfaceStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.states.solvent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(tip.title, style: text.bodyLarge),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(tip.body, style: text.bodyMedium),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'Got it',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: Text(
                        'Got it',
                        style: text.bodyLarge?.copyWith(
                          color: tokens.states.solvent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
