import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';

/// One thing the app does, and where to find it.
final class TourFeature {
  const TourFeature(this.title, this.detail, {this.where});

  final String title;

  /// One or two plain sentences. What it does, not why it is good.
  final String detail;

  /// The tab or screen it lives on, or null when it has no single place.
  final String? where;
}

/// A group of features under one heading.
final class TourSection {
  const TourSection(this.heading, this.features);

  final String heading;
  final List<TourFeature> features;
}

/// Everything LockIn can do, grouped by the loop.
///
/// Public so a test can hold the copy to the same tone rules as the rest of
/// the app, and so a feature added later has one obvious place to be listed.
const tourSections = [
  TourSection('Plan', [
    TourFeature(
      'Today',
      'The day as one list. Drag a row to reorder it, tick it when it is '
          'done.',
      where: 'Today',
    ),
    TourFeature(
      'Your list',
      'Tasks wait here until you put them on a day. From my list, on '
          'Today, adds several at once.',
      where: 'Tasks',
    ),
    TourFeature(
      'Repeating tasks and habits',
      'They add themselves on the days they are due. Remove a row to skip '
          'it for the day.',
      where: 'Tasks',
    ),
    TourFeature(
      'Projects and avoided tasks',
      'Group tasks under a project, or mark the one you keep putting off and '
          'LockIn counts the days.',
      where: 'Tasks',
    ),
    TourFeature(
      'Today’s suggestion',
      'One small idea a day. Add it or say not now, and it will not come '
          'back for a while.',
      where: 'Today',
    ),
  ]),
  TourSection('Earn', [
    TourFeature(
      'Ticking pays',
      'A ticked task pays its estimate in minutes.',
      where: 'Today',
    ),
    TourFeature(
      'Focus blocks',
      'Play on a task starts a timer. It keeps counting with the screen off, '
          'an alarm rings at the end, and a finished block ticks its task.',
      where: 'Today',
    ),
  ]),
  TourSection('Spend', [
    TourFeature(
      'Watched apps',
      'Time in the apps you pick spends minutes. Nothing else is counted.',
      where: 'Settings',
    ),
    TourFeature(
      'Your rules',
      'How much a focused minute buys, a daily allowance, the caps, and the '
          'hour your day starts.',
      where: 'Settings',
    ),
    TourFeature(
      'Borrowing',
      'Past zero the balance goes negative and says so. A short grace runs '
          'first.',
      where: 'Balance',
    ),
    TourFeature(
      'Savings and treats',
      'Minutes above the rollover cap move to savings at the end of the day. '
          'Spend them on a treat and they are gone for good.',
      where: 'Balance',
    ),
    TourFeature(
      'Blocking, if you want it',
      'Off unless you turn it on. Remind shows a page when the minutes run '
          'out, Block keeps the app covered until you earn more.',
      where: 'Settings',
    ),
  ]),
  TourSection('Home screen', [
    TourFeature(
      'Today widget',
      'The day’s list and your balance without opening the app. It moves to '
          'the new day on its own.',
    ),
    TourFeature(
      'Capture widget',
      'Write a task down in one line. It lands on today’s list the next time '
          'LockIn opens.',
    ),
  ]),
  TourSection('Look back', [
    TourFeature(
      'Statement',
      'What was earned and spent, day by day.',
      where: 'Stats',
    ),
    TourFeature(
      'Insights',
      'When you start, what you focus on, how much of it was phone-down.',
      where: 'Stats',
    ),
    TourFeature(
      'Stickers',
      'Finished tasks fill a page. Locked ones say how to get them.',
      where: 'Stats',
    ),
  ]),
  TourSection('Elsewhere', [
    TourFeature(
      'Goals',
      'Year and someday goals. They never join a day.',
      where: 'Settings',
    ),
    TourFeature(
      'Check the numbers',
      'Compare what LockIn counted against what your phone says.',
      where: 'Settings',
    ),
    TourFeature(
      'Backup and export',
      'One file that carries everything to a new phone, or a spreadsheet to '
          'read.',
      where: 'Settings',
    ),
    TourFeature(
      'Themes',
      'Aurora or Blush, light, dark or following the phone. The widgets '
          'follow.',
      where: 'Settings',
    ),
  ]),
];

/// What LockIn can do, all of it, whenever someone asks.
///
/// First run shows only the loop and each screen explains itself once. This is
/// the rest, in one place, for the person who wants the whole list or who
/// dismissed a tip too fast.
class TourScreen extends StatelessWidget {
  const TourScreen({this.onBack, this.onReplayTips, super.key});

  final VoidCallback? onBack;

  /// Shows every one-time tip again, from the next screen opened.
  final VoidCallback? onReplayTips;

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
                  Expanded(
                    child: Text(
                      'What LockIn can do',
                      style: text.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    'The whole app on one page. Each screen also explains '
                    'itself once, the first time it opens.',
                    style: text.bodyMedium,
                  ),
                  for (final section in tourSections) ...[
                    const SizedBox(height: 24),
                    Text(section.heading.toUpperCase(), style: text.labelSmall),
                    const SizedBox(height: 10),
                    for (final feature in section.features)
                      _FeatureRow(feature: feature),
                  ],
                  if (onReplayTips != null) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      button: true,
                      label: 'Show the tips again',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onReplayTips,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: tokens.states.solvent),
                          ),
                          child: Text(
                            'Show the tips again',
                            style: text.bodyLarge?.copyWith(
                              color: tokens.states.solvent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final TourFeature feature;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(feature.title, style: text.bodyLarge)),
              if (feature.where case final where?)
                Text(where, style: text.labelMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(feature.detail, style: text.bodyMedium),
        ],
      ),
    );
  }
}
