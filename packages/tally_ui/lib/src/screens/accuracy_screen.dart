import 'package:flutter/material.dart';

import '../format/durations.dart';
import '../theme/tally_theme_data.dart';

/// One watched app's day, as LockIn counted it.
final class AccuracyApp {
  const AccuracyApp({
    required this.packageName,
    required this.label,
    required this.seconds,
    this.reportedMinutes,
  });

  final String packageName;
  final String label;

  /// What LockIn counted.
  final int seconds;

  /// What the user read off Digital Wellbeing, if they have entered it.
  final int? reportedMinutes;

  int get minutes => wholeMinutes(seconds);

  /// Positive means LockIn counted more than the phone did.
  int? get differenceMinutes =>
      reportedMinutes == null ? null : minutes - reportedMinutes!;
}

final class AccuracyDay {
  const AccuracyDay({
    required this.dayKey,
    required this.label,
    required this.apps,
  });

  final String dayKey;
  final String label;
  final List<AccuracyApp> apps;

  bool get hasAnything => apps.isNotEmpty;
}

/// Checking LockIn's numbers against the phone's own.
///
/// **This is the app's foundation, and it is the one thing the app cannot
/// check for itself.** Every screen in LockIn is arithmetic on top of one
/// measurement: how long a watched app was in the foreground. If that
/// measurement is wrong then the balance, the statement, the insights and the
/// streak are all confidently wrong together, and no amount of internal
/// consistency would reveal it.
///
/// So the comparison is a screen rather than a note in a plan. It puts what
/// LockIn counted next to a box for what Digital Wellbeing says, keeps the
/// answer, and states plainly how much disagreement is normal. A check nobody
/// records is a check that gets done once and forgotten.
class AccuracyScreen extends StatelessWidget {
  const AccuracyScreen({
    required this.days,
    this.onBack,
    this.onReport,
    super.key,
  });

  final List<AccuracyDay> days;
  final VoidCallback? onBack;

  /// Records what Digital Wellbeing said. Null clears it.
  final void Function(String dayKey, String packageName, int? minutes)?
      onReport;

  /// How far apart the two can be before it is worth investigating.
  ///
  /// Two minutes is not slack, it is the honest resolution of the comparison:
  /// the two count session edges slightly differently and both round. Beyond
  /// five, something is actually wrong.
  static const closeEnoughMinutes = 2;
  static const worthInvestigatingMinutes = 5;

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
                  Text('Check the numbers', style: text.headlineMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Everything in LockIn is arithmetic on one '
                          'measurement: how long a watched app was open. If '
                          'that is wrong, every other number is wrong with it '
                          'and nothing inside the app would show it.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Open your phone Settings, then Digital Wellbeing '
                          'and parental controls, then the dashboard. Pick a '
                          'day, and type what it says for each app.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A minute or two apart is expected: the two count '
                          'the edges of a session slightly differently and '
                          'both round. More than five is worth telling me '
                          'about.',
                          style: text.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (days.every((d) => !d.hasAnything))
                    Text(
                      'Nothing counted yet. This fills in once a watched app '
                      'has been open for a while.',
                      style: text.bodyMedium,
                    ),
                  for (final day in days)
                    if (day.hasAnything) _Day(day: day, onReport: onReport),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, this.onReport});

  final AccuracyDay day;
  final void Function(String dayKey, String packageName, int? minutes)?
      onReport;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day.label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: 8),
          for (final app in day.apps)
            _AppRow(
              day: day,
              app: app,
              onReport: onReport,
            ),
        ],
      ),
    );
  }
}

class _AppRow extends StatefulWidget {
  const _AppRow({required this.day, required this.app, this.onReport});

  final AccuracyDay day;
  final AccuracyApp app;
  final void Function(String dayKey, String packageName, int? minutes)?
      onReport;

  @override
  State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  late final _controller = TextEditingController(
    text: widget.app.reportedMinutes?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final difference = widget.app.differenceMinutes;

    final verdictColour = difference == null
        ? tokens.inkFaint
        : difference.abs() <= AccuracyScreen.closeEnoughMinutes
            ? tokens.states.solvent
            : difference.abs() <= AccuracyScreen.worthInvestigatingMinutes
                ? tokens.states.low
                : tokens.states.borrowing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.app.label,
                    style: text.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${widget.app.minutes}m', style: text.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Digital Wellbeing says',
                    style: text.labelMedium,
                  ),
                ),
                SizedBox(
                  width: 78,
                  height: 40,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge,
                    cursorColor: tokens.states.solvent,
                    decoration: InputDecoration(
                      hintText: 'min',
                      hintStyle: text.labelMedium,
                      filled: true,
                      fillColor: tokens.surfaceStrong,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final trimmed = value.trim();
                      widget.onReport?.call(
                        widget.day.dayKey,
                        widget.app.packageName,
                        trimmed.isEmpty ? null : int.tryParse(trimmed),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (difference != null) ...[
              const SizedBox(height: 8),
              Text(
                switch (difference) {
                  0 => 'Exactly the same.',
                  final d when d.abs() <=
                          AccuracyScreen.closeEnoughMinutes =>
                    '${d.abs()} minute${d.abs() == 1 ? '' : 's'} apart. That '
                        'is within rounding.',
                  final d when d > 0 =>
                    'LockIn counted $d minutes more than your phone did.',
                  final d =>
                    'LockIn counted ${-d} minutes less than your phone did.',
                },
                style: text.labelMedium?.copyWith(color: verdictColour),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
