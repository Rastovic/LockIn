import 'dart:async';

import 'package:flutter/material.dart';

import '../format/durations.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/state_colors.dart';
import '../theme/tally_theme_data.dart';
import '../widgets/balance_strip.dart';
import '../widgets/sticker_chip.dart';

/// The focus session.
///
/// **No ads on this screen, ever.** Not at the start, not at the end, not in
/// the corner. This is the screen the whole app is for.
///
/// The countdown redraws once a second, but the number comes from [FocusRun]
/// and the wall clock every time. The ticker decides *when* to repaint, never
/// *what* it says: a block backgrounded for twenty minutes is twenty minutes
/// further along when the screen comes back.
class FocusScreen extends StatefulWidget {
  const FocusScreen({
    required this.run,
    required this.earnRatio,
    this.taskTitle,
    this.stickerId,
    this.onPause,
    this.onResume,
    this.onExtend,
    this.onGiveUp,
    this.onComplete,
    this.clock,
    this.alarmBlocked = false,
    this.alarmImprecise = false,
    this.onFixAlarm,
    super.key,
  });

  final FocusRun run;

  /// Minutes earned per minute focused, stated on screen so the deal is never
  /// a guess.
  final double earnRatio;

  final String? taskTitle;
  final String? stickerId;

  /// Notifications are off, so the end-of-block alarm cannot ring.
  ///
  /// Said on screen rather than swallowed. The whole reason the alarm exists
  /// is that people leave this screen during a block - if it cannot ring, the
  /// user has to know now, not by missing the end of a block later.
  final bool alarmBlocked;

  /// The alarm will ring, but Android may hold it for minutes.
  ///
  /// Worth its own line rather than folding into [alarmBlocked]: a block that
  /// ends at 14:00 and rings at 14:04 is not a quieter version of silence, it
  /// is a timer the user stops trusting. Off by default on recent Android, so
  /// this is the state a fresh install is in until someone says otherwise.
  final bool alarmImprecise;

  /// Opens the OS switch for exact alarms.
  final VoidCallback? onFixAlarm;

  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final void Function(Duration by)? onExtend;
  final VoidCallback? onGiveUp;

  /// Fired once when the clock reaches the target.
  final VoidCallback? onComplete;

  /// Injectable so tests do not have to wait in real time.
  final DateTime Function()? clock;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _ticker;
  bool _completionReported = false;

  DateTime get _now => (widget.clock ?? () => DateTime.now().toUtc())();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    if (!_completionReported &&
        widget.run.isRunning &&
        widget.run.isComplete(_now)) {
      _completionReported = true;
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final run = widget.run;
    final now = _now;
    final remaining = run.remainingSeconds(now);

    // Earned so far, stated live. The plan's rule is that the rate is said out
    // loud; showing the running total makes it concrete rather than a promise.
    final earnedMinutes =
        wholeMinutes((run.elapsedSeconds(now) * widget.earnRatio).round());

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            if (widget.taskTitle != null)
              _TaskChip(title: widget.taskTitle!, stickerId: widget.stickerId),
            const SizedBox(height: 28),
            Stack(
              alignment: Alignment.center,
              children: [
                StateGlow(
                  color: tokens.states.solvent,
                  width: 300,
                  height: 150,
                  opacity: run.isPaused ? 0.18 : 0.4,
                ),
                Text(
                  FocusRun.format(remaining),
                  style: text.displayLarge?.copyWith(
                    color: run.isPaused ? tokens.inkMuted : tokens.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              run.isPaused
                  ? 'Paused'
                  : _rateLine(run.target.inMinutes, widget.earnRatio),
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.alarmBlocked && !run.isPaused) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Notifications are off, so nothing will ring when this ends. '
                  'You can turn them on in your phone settings.',
                  style: text.labelMedium?.copyWith(color: tokens.states.low),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (!widget.alarmBlocked &&
                widget.alarmImprecise &&
                !run.isPaused) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Semantics(
                  button: widget.onFixAlarm != null,
                  label: 'Allow exact alarms',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: widget.onFixAlarm,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Android may hold this alarm for a few minutes.'
                      '${widget.onFixAlarm == null ? '' : ' Tap to allow '
                          'exact alarms.'}',
                      style: text.labelMedium?.copyWith(
                        color: tokens.states.low,
                        decoration: widget.onFixAlarm == null
                            ? null
                            : TextDecoration.underline,
                        decorationColor: tokens.states.low,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
            if (run.phoneDownRequested) ...[
              const SizedBox(height: 6),
              Text(
                run.screenUnlockedDuringBlock
                    ? 'Screen came on, so this one pays 1.0x'
                    : 'Phone down · pays 1.5x while the screen stays off',
                style: text.labelMedium?.copyWith(
                  color: run.screenUnlockedDuringBlock
                      ? tokens.states.low
                      : tokens.states.solvent,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 4),
            Text('$earnedMinutes min earned so far', style: text.labelMedium),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final minutes in [5, 10, 20]) ...[
                  _Extend(
                    minutes: minutes,
                    onTap: () =>
                        widget.onExtend?.call(Duration(minutes: minutes)),
                  ),
                  if (minutes != 20) const SizedBox(width: 8),
                ],
              ],
            ),
            const Spacer(),
            _WideButton(
              label: run.isPaused ? 'Resume' : 'Pause',
              onTap: run.isPaused ? widget.onResume : widget.onPause,
              filled: run.isPaused,
            ),
            const SizedBox(height: 8),
            // Stated plainly, because a user weighing whether to stop should
            // not have to guess what it costs. It costs nothing.
            _WideButton(
              label: 'Give up · costs nothing',
              onTap: widget.onGiveUp,
              filled: false,
              muted: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// "20 min = 20 min", or the honest version when the ratio is not 1:1.
  static String _rateLine(int targetMinutes, double ratio) {
    final earns = (targetMinutes * ratio).floor();
    return '$targetMinutes min focused = $earns min of scrolling';
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.title, this.stickerId});

  final String title;
  final String? stickerId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StickerChip(stickerId: stickerId, size: 22),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _Extend extends StatelessWidget {
  const _Extend({required this.minutes, required this.onTap});

  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: 'Add $minutes minutes',
      // Without this the '+5' Text produces its own node and competes with the
      // label, leaving the button unreachable by name. See NOTES.md.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          constraints: const BoxConstraints(minWidth: 64),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '+$minutes',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.inkMuted,
                ),
          ),
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.onTap,
    required this.filled,
    this.muted = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? tokens.states.solvent : const Color(0x00000000),
              border: filled
                  ? null
                  : Border.all(color: tokens.surfaceStrong),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: filled
                        ? tokens.bg
                        : (muted ? tokens.inkFaint : tokens.ink),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a finished block credited.
///
/// Debt is paid before the balance rises, so this states both: a user who was
/// 20 minutes down and earned 25 should see where the first 20 went rather than
/// wondering why the number only moved by five.
class FocusCompleteScreen extends StatelessWidget {
  const FocusCompleteScreen({
    required this.creditedSeconds,
    required this.debtClearedSeconds,
    required this.newBalanceSeconds,
    this.phoneDownBonus = false,
    this.cappedSeconds = 0,
    this.onKeepGoing,
    this.onMarkDone,
    this.onStopForToday,
    super.key,
  });

  final int creditedSeconds;

  /// How much of the credit went to clearing a debt rather than to balance.
  final int debtClearedSeconds;

  final int newBalanceSeconds;
  final bool phoneDownBonus;

  /// Earned but refused by the daily cap. Shown so the cap is visible rather
  /// than mysterious.
  final int cappedSeconds;

  final VoidCallback? onKeepGoing;
  final VoidCallback? onMarkDone;
  final VoidCallback? onStopForToday;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final state = BalanceState.forSeconds(newBalanceSeconds);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text('${wholeMinutes(creditedSeconds)}', style: text.displayLarge),
            const SizedBox(height: 4),
            Text(
              phoneDownBonus ? 'minutes earned, phone down' : 'minutes earned',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 26),
            if (debtClearedSeconds > 0)
              _Line(
                label: 'went to clearing your debt',
                value: '${wholeMinutes(debtClearedSeconds)} min',
                color: tokens.states.borrowing,
              ),
            if (cappedSeconds > 0)
              _Line(
                label: 'over today’s earn cap',
                value: '${wholeMinutes(cappedSeconds)} min',
                color: tokens.states.low,
              ),
            _Line(
              label: 'balance now',
              value: '${formatMinutes(newBalanceSeconds)} min',
              color: tokens.colorFor(state),
            ),
            const Spacer(),
            _WideButton(
              label: 'Keep going · +20',
              onTap: onKeepGoing,
              filled: true,
            ),
            const SizedBox(height: 8),
            _WideButton(label: 'Mark done', onTap: onMarkDone, filled: false),
            const SizedBox(height: 8),
            _WideButton(
              label: 'Stop for today',
              onTap: onStopForToday,
              filled: false,
              muted: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(value, style: text.bodyLarge?.copyWith(color: color)),
        ],
      ),
    );
  }
}
