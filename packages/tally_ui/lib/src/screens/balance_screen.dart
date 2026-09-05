import 'package:flutter/material.dart';

import '../format/durations.dart';

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
    this.sessions = const [],
  });

  final String packageName;
  final String label;
  final int seconds;

  /// True when the app is absent from this device.
  ///
  /// A restored backup naming apps this phone does not have keeps them, greyed,
  /// with their history intact.
  final bool notInstalled;

  /// When today's time in this app actually happened, in order.
  ///
  /// Shown because the first reaction to a large number is to doubt it, and
  /// "you spent 66 minutes" is not a claim anyone can check. A list of times
  /// is: either it matches the afternoon you remember, or it does not and the
  /// app has a real bug worth reporting. A ledger that cannot be audited is
  /// asking to be taken on faith, which is the one thing it has not earned.
  final List<AppSession> sessions;

  int get minutes => wholeMinutes(seconds);
}

/// One unbroken stretch in an app.
final class AppSession {
  const AppSession({required this.startedAt, required this.endedAt});

  final DateTime startedAt;
  final DateTime endedAt;

  int get seconds => endedAt.difference(startedAt).inSeconds;
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
    this.openingSeconds = 0,
    this.allowanceSeconds = 0,
    this.graceUsedSeconds = 0,
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

  /// What was carried in from yesterday, before today added anything.
  final int openingSeconds;

  /// Today's grant.
  final int allowanceSeconds;

  /// Grace actually consumed today, which is a credit like any other.
  final int graceUsedSeconds;

  int get netSeconds => earnedSeconds - spentSeconds;
}

/// How today's number was arrived at, line by line.
///
/// Added after the first day of real use, where the app showed a balance of −2
/// on one screen, 66 minutes of spend on another and 67 on a third, and no
/// relationship between any of them. The numbers were right and reconciled
/// exactly - 60 granted plus 5 of grace against 67 spent - but nothing on
/// screen said so, and a ledger nobody can check is a ledger nobody trusts.
///
/// It shows the terms rather than a sentence about them, because the question
/// being answered is arithmetic and prose is a worse way to answer it.
class _Sum extends StatelessWidget {
  const _Sum({required this.model});

  final BalanceScreenModel model;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    // Every term is whole minutes, floored from its own seconds and only then
    // given its sign. The order matters: flooring towards negative infinity
    // *after* negating a debit rounds it away from zero, so 97m40s of spend
    // rendered as floor(−5860) reads −98 while the SPENT tile below the block
    // shows floor(5860) = 97. Same seconds, two numbers, which is exactly the
    // disagreement this block exists to rule out.
    final terms = <(String, int)>[
      if (model.openingSeconds != 0)
        ('Carried in', wholeMinutes(model.openingSeconds)),
      ('Allowance today', wholeMinutes(model.allowanceSeconds)),
      if (model.earnedSeconds > 0)
        ('Earned focusing', wholeMinutes(model.earnedSeconds)),
      if (model.graceUsedSeconds > 0)
        ('Grace', wholeMinutes(model.graceUsedSeconds)),
      if (model.spentSeconds > 0)
        ('Spent on apps', -wholeMinutes(model.spentSeconds)),
      // The debt floor is why a day can spend 97 against a −55 carry-in and
      // still land at −60: past the floor the minutes are recorded but stop
      // being charged. It is a term in the sum, so it belongs in the list -
      // left out, the column simply does not add up, and the note under the
      // block was being asked to explain arithmetic the arithmetic should
      // state itself.
      if (model.unrepayableSeconds > 0)
        ('Not charged, past the floor', wholeMinutes(model.unrepayableSeconds)),
    ];
    if (terms.length < 2) return const SizedBox.shrink();

    final totalMinutes = wholeMinutes(model.spendableSeconds);
    final termSum = terms.fold(0, (sum, term) => sum + term.$2);
    // Each term is floored on its own, so the parts can land a minute off the
    // total. Named rather than hidden: an unexplained one-minute gap in a
    // column of eight is what makes a reader stop trusting all eight.
    //
    // Flooring is the only thing that lands here today, because the terms
    // above are the whole identity: opening + allowance + earned + grace −
    // spent + refused-by-the-floor is exactly the ledger's spendable. Anything
    // new that moves the balance - a hand transfer to savings, say - needs its
    // own line, or it turns up in this one calling itself rounding.
    if (termSum != totalMinutes) {
      terms.add(('Rounding', totalMinutes - termSum));
    }

    Widget line(String label, int minutes, {bool total = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: total
                  ? text.bodyMedium?.copyWith(color: tokens.ink)
                  : text.bodyMedium,
            ),
          ),
          Text(
            // Signed, because the whole point is which way each term
            // pushes. A bare "67" in a list of credits reads as a credit.
            minutes > 0 && !total ? '+$minutes' : formatMinutes(minutes * 60),
            style: text.bodyMedium?.copyWith(
              color: total ? tokens.ink : tokens.inkMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW THIS ADDS UP', style: text.labelSmall),
            const SizedBox(height: 8),
            for (final (label, seconds) in terms) line(label, seconds),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(height: 1, color: tokens.surfaceStrong),
            ),
            line('Left to spend', totalMinutes, total: true),
            if (model.spendableSeconds < 0) ...[
              const SizedBox(height: 10),
              Text(
                // The word the user did not recognise, defined where the
                // number that earned it is standing.
                'Below zero is borrowing: tomorrow opens with this much '
                'already spent. Nothing is blocked, and focusing pays it '
                'back.',
                style: text.labelMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
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
        // Scrolls rather than fills. It was a fixed Column with two Spacers,
        // which fit exactly until the sum block was added and then overflowed
        // by 42px on a phone-sized screen - and the spend list, which grows
        // with every app being watched, would have done the same eventually.
        // Anything laid out to fit precisely is a layout waiting to break the
        // first time someone raises their text size.
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 18),
              _Sum(model: model),
              if (model.unrepayableSeconds > 0) ...[
                const SizedBox(height: 12),
                Text(
                  // The figure itself is a line in the block above now, so
                  // this defines the rule rather than repeating the number.
                  'Debt stops at −60. Past that the minutes still show in the '
                  "day's spend, but what you have to repay stops growing.",
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
                      value: '${wholeMinutes(model.earnedSeconds)}',
                      color: tokens.states.solvent,
                    ),
                    const SizedBox(width: 8),
                    _Stat(
                      label: 'SPENT',
                      value: '${wholeMinutes(model.spentSeconds)}',
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
              const SizedBox(height: 26),
              if (model.spendByApp.isNotEmpty)
                _SpendList(spend: model.spendByApp)
              else
                _NoSpendYet(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitleFor(BalanceState state) => switch (state) {
    BalanceState.borrowing => 'minutes borrowed',
    _ => 'minutes left today',
  };

  static String _hours(int seconds) {
    final minutes = wholeMinutes(seconds);
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: tokens.states.savings),
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

/// Where today's spend went, and when.
///
/// Each app opens to the actual stretches of time behind its total. Added
/// after a first day of use produced "66 minutes in an app I did not open",
/// which a single total gives you no way to investigate. With the times
/// showing, the number is either recognisable or demonstrably wrong, and both
/// of those are better than unfalsifiable.
class _SpendList extends StatefulWidget {
  const _SpendList({required this.spend});

  final List<AppSpend> spend;

  @override
  State<_SpendList> createState() => _SpendListState();
}

class _SpendListState extends State<_SpendList> {
  String? _open;

  static String _time(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final total = widget.spend.fold(0, (sum, app) => sum + app.seconds);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHERE IT WENT', style: text.labelSmall),
          const SizedBox(height: 10),
          for (final app in widget.spend.take(5)) ...[
            Semantics(
              button: app.sessions.isNotEmpty,
              expanded: _open == app.packageName,
              label: '${app.label}, ${app.minutes} minutes',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: app.sessions.isEmpty
                    ? null
                    : () => setState(
                        () => _open = _open == app.packageName
                            ? null
                            : app.packageName,
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.label,
                            style: text.bodyLarge?.copyWith(
                              color: app.notInstalled
                                  ? tokens.inkFaint
                                  : tokens.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${app.minutes}m', style: text.labelMedium),
                        if (app.sessions.isNotEmpty)
                          Icon(
                            _open == app.packageName
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: tokens.inkFaint,
                          ),
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
                          app.notInstalled
                              ? tokens.inkFaint
                              : tokens.states.borrowing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_open == app.packageName)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final session in app.sessions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_time(session.startedAt)} to '
                                '${_time(session.endedAt)}',
                                style: text.labelMedium,
                              ),
                            ),
                            Text(
                              formatDuration(session.seconds),
                              style: text.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    if (app.sessions.isEmpty)
                      Text('No times recorded.', style: text.labelMedium),
                  ],
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
