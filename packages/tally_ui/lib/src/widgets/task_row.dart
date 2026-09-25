import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';
import 'sticker_chip.dart';

/// One row of today's plan.
///
/// Layout, settled at review on 2026-08-10: grip, sticker, title, estimate,
/// then **both controls grouped on the right**. Grouping them lets the sticker
/// and title read as one unit starting near the left edge, and keeps every
/// tappable thing in one place.
///
/// Ticking stamps the sticker and pays the task's estimate, as a session the
/// controller banks. The row itself knows nothing about minutes.
class TaskRow extends StatelessWidget {
  const TaskRow({
    required this.title,
    required this.done,
    this.stickerId,
    this.estimateMinutes,
    this.subtitle,
    this.onToggle,
    this.onStartFocus,
    this.showGrip = true,
    this.stampOnMount = false,
    super.key,
  });

  final String title;
  final bool done;
  final String? stickerId;
  final int? estimateMinutes;

  /// Week dots, a streak, or an avoided-days count.
  final String? subtitle;

  final VoidCallback? onToggle;
  final VoidCallback? onStartFocus;
  final bool showGrip;

  /// Plays the sticker's stamp as the row appears, for a row that was just
  /// ticked and has been rebuilt in the done section.
  final bool stampOnMount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: title,
      checked: done,
      child: Container(
        // A done row is tinted with the solvent colour, so finished work
        // reads as a different kind of row at a glance, not only as
        // struck-through text.
        decoration: BoxDecoration(
          color: done
              ? Color.alphaBlend(
                  tokens.states.solvent.withValues(alpha: 0.12),
                  tokens.surface,
                )
              : tokens.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        child: Row(
          children: [
            if (showGrip) ...[
              Icon(Icons.drag_indicator, size: 16, color: tokens.inkFaint),
              const SizedBox(width: 4),
            ],
            StickerChip(
              stickerId: stickerId,
              stamped: done,
              stampOnMount: stampOnMount,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.bodyLarge?.copyWith(
                      color: done ? tokens.inkFaint : tokens.ink,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: tokens.inkFaint,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) Text(subtitle!, style: text.labelMedium),
                ],
              ),
            ),
            if (estimateMinutes != null) ...[
              const SizedBox(width: 8),
              Text('${estimateMinutes}m', style: text.labelMedium),
            ],
            const SizedBox(width: 6),
            _DoneDot(done: done, onTap: onToggle, title: title),
            if (onStartFocus != null)
              _PlayButton(onTap: onStartFocus!, title: title),
          ],
        ),
      ),
    );
  }
}

/// The completion control.
///
/// **Deliberately quiet.** Settled at review: a thin ring that fills solid, with
/// no tick glyph inside. The row already says done three other ways - the title
/// is struck through, dimmed, and the sticker has stamped - so a check mark was
/// a fourth signal and the loudest of them. A plan should not read like a form.
class _DoneDot extends StatelessWidget {
  const _DoneDot({required this.done, required this.onTap, required this.title});

  final bool done;
  final VoidCallback? onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      label: done ? 'Mark $title not done' : 'Mark $title done',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 44pt around a 16pt visual. The floor is not negotiable, and this is
        // the most-tapped control in the app.
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? tokens.states.solvent : const Color(0x00000000),
                border: Border.all(
                  color: done ? tokens.states.solvent : tokens.inkFaint,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap, required this.title});

  final VoidCallback onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: 'Start a focus session on $title',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: tokens.surfaceStrong,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: tokens.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
