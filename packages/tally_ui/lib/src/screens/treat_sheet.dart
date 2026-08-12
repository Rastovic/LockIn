import 'package:flutter/material.dart';

import '../format/durations.dart';

import '../theme/tally_theme_data.dart';

/// Something to spend savings on that is not a screen.
final class TreatIdea {
  const TreatIdea(this.label, this.glyph);

  final String label;
  final String glyph;

  /// Deliberately ordinary and cheap. A list of expensive things would make
  /// the reward feel out of reach, and the point is that it is not.
  static const suggestions = [
    TreatIdea('Lunch with a friend', '🍜'),
    TreatIdea('Cinema', '🎬'),
    TreatIdea('A book', '📚'),
    TreatIdea('A massage', '💆'),
    TreatIdea('A day out', '🚋'),
    TreatIdea('Something you have wanted', '🎁'),
  ];
}

/// Spending savings on something off-screen.
///
/// **The counterweight to the whole app.** Without it Tally only ever takes
/// things away, and a ledger that never pays out is a scold with arithmetic.
///
/// The minutes are **burned, not converted**. They do not come back as scroll
/// time under any sequence of transfers, and the confirmation says so in those
/// words rather than leaving it to be discovered.
class TreatSheet extends StatefulWidget {
  const TreatSheet({
    required this.savingsSeconds,
    required this.onTreat,
    super.key,
  });

  final int savingsSeconds;

  /// Called with the label and the seconds to burn.
  final void Function(String label, int seconds) onTreat;

  @override
  State<TreatSheet> createState() => _TreatSheetState();
}

class _TreatSheetState extends State<TreatSheet> {
  String? _label;
  final _custom = TextEditingController();
  _Amount _amount = _Amount.half;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  int get _seconds => switch (_amount) {
        _Amount.all => widget.savingsSeconds,
        _Amount.half => widget.savingsSeconds ~/ 2,
        _Amount.hour => widget.savingsSeconds.clamp(0, 3600),
      };

  String get _chosenLabel =>
      _custom.text.trim().isNotEmpty ? _custom.text.trim() : (_label ?? '');

  bool get _canConfirm => _chosenLabel.isNotEmpty && _seconds > 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.surfaceStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Treat yourself', style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'You have ${_hm(widget.savingsSeconds)} saved. Savings can '
                'never be spent on scrolling, so this is what they are for.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text('ON WHAT', style: text.labelSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final idea in TreatIdea.suggestions)
                    Semantics(
                      button: true,
                      selected: _label == idea.label,
                      label: idea.label,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _label = _label == idea.label ? null : idea.label;
                          _custom.clear();
                        }),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _label == idea.label
                                ? tokens.states.savings
                                : tokens.surface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${idea.glyph}  ${idea.label}',
                            style: text.bodyLarge?.copyWith(
                              color: _label == idea.label
                                  ? tokens.bg
                                  : tokens.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _custom,
                onChanged: (_) => setState(() => _label = null),
                style: text.bodyLarge,
                cursorColor: tokens.states.savings,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Or something else',
                  hintStyle: text.bodyMedium,
                  filled: true,
                  fillColor: tokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('HOW MUCH', style: text.labelSmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final amount in _Amount.values) ...[
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _amount == amount,
                        label: amount.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => setState(() => _amount = amount),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _amount == amount
                                  ? tokens.states.savings
                                  : tokens.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              amount.label,
                              style: text.bodyLarge?.copyWith(
                                color: _amount == amount
                                    ? tokens.bg
                                    : tokens.inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (amount != _Amount.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  // Said plainly, before the button, in the words that matter.
                  // A user who thinks these minutes are being moved somewhere
                  // will feel robbed the first time they look for them.
                  '${_hm(_seconds)} will be gone. Treated minutes are spent, '
                  'not moved: they do not come back as scroll time.',
                  style: text.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                enabled: _canConfirm,
                label: 'Treat yourself',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _canConfirm
                      ? () => widget.onTreat(_chosenLabel, _seconds)
                      : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _canConfirm
                          ? tokens.states.savings
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _canConfirm
                          ? 'Spend ${_hm(_seconds)} on this'
                          : 'Pick what it is for',
                      style: text.bodyLarge?.copyWith(
                        color: _canConfirm ? tokens.bg : tokens.inkFaint,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hm(int seconds) {
    final minutes = wholeMinutes(seconds);
    if (minutes < 60) return '${minutes}m';
    final rest = minutes % 60;
    return rest == 0
        ? '${minutes ~/ 60}h'
        : '${minutes ~/ 60}h ${rest}m';
  }
}

enum _Amount {
  all('All of it'),
  half('Half'),
  hour('An hour');

  const _Amount(this.label);

  final String label;
}
