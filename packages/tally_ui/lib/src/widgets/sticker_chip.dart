import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';

/// A task's category sticker.
///
/// **Settled decision 18: completing a task stamps its sticker.** The chip
/// scales up and settles when a row is ticked, so the second currency is
/// legible at the moment it is earned rather than only on the monthly sheet.
///
/// This is the one animation the app's flat tone allows. It is not a
/// celebration - no confetti, no sound, no bounce past 1.0 that reads as
/// cartoonish. A stamp is a firm press and a settle, which is why the curve
/// overshoots once and comes back rather than springing.
class StickerChip extends StatefulWidget {
  const StickerChip({
    required this.stickerId,
    this.stamped = false,
    this.size = 26,
    super.key,
  });

  /// Which sticker. Rendered as its glyph until the drawn assets land in
  /// Phase 5c; the id is what persists either way.
  final String stickerId;

  /// True once the task is complete. Transitioning false to true runs the
  /// stamp.
  final bool stamped;

  final double size;

  @override
  State<StickerChip> createState() => _StickerChipState();
}

class _StickerChipState extends State<StickerChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 320),
    vsync: this,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    // Press: a quick lift, so the eye catches it.
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.18)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    // Settle: back down, slightly past, then home. A stamp lands, it does not
    // bounce.
    TweenSequenceItem(
      tween: Tween(begin: 1.18, end: 0.97)
          .chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.97, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(StickerChip old) {
    super.didUpdateWidget(old);
    if (widget.stamped && !old.stamped) {
      // Respect reduced motion. Section 6 of DESIGN-SYSTEM.md calls this an
      // accessibility requirement rather than a nicety, so the stamp is skipped
      // entirely rather than shortened - a fast animation is still animation.
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    } else if (!widget.stamped && old.stamped) {
      // Unticking is a mis-tap correction and must cost nothing, including
      // visually. It reverts with no animation at all.
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: tokens.surfaceStrong,
          borderRadius: BorderRadius.circular(widget.size * 0.34),
        ),
        alignment: Alignment.center,
        child: Text(
          stickerGlyphs[widget.stickerId] ?? '·',
          style: TextStyle(fontSize: widget.size * 0.52),
          // The glyph is decorative; the row's title already names the task.
          semanticsLabel: '',
        ),
      ),
    );
  }
}

/// Stand-in glyphs for the 24 base stickers.
///
/// Replaced by the drawn assets in Phase 5c. The ids are the contract and do
/// not change when the art lands, so nothing downstream has to move.
const stickerGlyphs = <String, String>{
  'cleaning': '🧴',
  'dishes': '🍽',
  'laundry': '🧺',
  'gym': '🏋',
  'run': '👟',
  'stretch': '🧘',
  'walk': '🚶',
  'study': '📚',
  'read': '📖',
  'write': '✍️',
  'work': '💻',
  'admin': '✉️',
  'money': '💰',
  'call': '📞',
  'shopping': '🧺',
  'cooking': '🍳',
  'plants': '🪴',
  'pets': '🐾',
  'selfcare': '🧼',
  'sleep': '🌙',
  'social': '💬',
  'creative': '🎨',
  'music': '🎵',
  'outdoors': '⛰',
};
