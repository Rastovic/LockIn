import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';

/// How long the block is, asked before it starts.
///
/// A focus block used to begin the instant the button was pressed, at whatever
/// the task's estimate happened to be - or twenty-five minutes when there was
/// no estimate. That made the length a property of the task rather than a
/// decision, and the decision is the whole point: how long *right now* is worth
/// giving is a different question every time it is asked.
///
/// Presets rather than a free number field, with one custom escape. Someone
/// about to focus is deciding between "a bit" and "a proper go", not between 43
/// and 44 minutes, and a keyboard between the intention and the timer is the
/// friction that gets a block skipped.
///
/// The task's own estimate is offered first when it has one, because the person
/// who wrote "45 min" on the task did already answer this once.
class DurationSheet extends StatefulWidget {
  const DurationSheet({
    required this.onStart,
    this.suggestedMinutes,
    this.taskTitle,
    super.key,
  });

  /// The task's estimate, offered as the leading choice when present.
  final int? suggestedMinutes;

  /// Named on the sheet so it is clear what is being started.
  final String? taskTitle;

  final ValueChanged<int> onStart;

  /// The fixed choices, in minutes.
  static const presets = [10, 15, 25, 45, 60, 90];

  @override
  State<DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<DurationSheet> {
  late int _minutes = widget.suggestedMinutes ?? 25;

  /// Presets plus the task's estimate, deduplicated and in order.
  List<int> get _choices {
    final all = {...DurationSheet.presets, if (_minutes > 0) _minutes}.toList()
      ..sort();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How long?', style: text.titleLarge),
          if (widget.taskTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.taskTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: tokens.inkMuted),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final minutes in _choices)
                _Choice(
                  minutes: minutes,
                  selected: minutes == _minutes,
                  onTap: () => setState(() => _minutes = minutes),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Minus before plus, five at a time. The presets cover the ordinary
          // case; this exists so an odd length is two taps rather than a
          // keyboard. It moves the selection itself, so the highlighted chip and
          // the start button are the only two places the length is stated - a
          // third readout next to these buttons said the same number twice.
          Row(
            children: [
              _Nudge(
                icon: Icons.remove,
                label: 'Five minutes less',
                enabled: _minutes > 5,
                onTap: () => setState(() => _minutes -= 5),
              ),
              const SizedBox(width: 10),
              _Nudge(
                icon: Icons.add,
                label: 'Five minutes more',
                enabled: _minutes < 240,
                onTap: () => setState(() => _minutes += 5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _StartButton(
            label: 'Start ${_label(_minutes)}',
            onTap: () => widget.onStart(_minutes),
          ),
        ],
      ),
    );
  }

  static String _label(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: _DurationSheetState._label(minutes),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? tokens.states.solvent : tokens.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _DurationSheetState._label(minutes),
            style: text.bodyLarge?.copyWith(
              color: selected ? tokens.bg : tokens.ink,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _Nudge extends StatelessWidget {
  const _Nudge({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? tokens.ink : tokens.inkFaint,
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 52,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.states.solvent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: text.bodyLarge?.copyWith(
              color: tokens.bg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
