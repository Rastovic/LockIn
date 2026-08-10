import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';
import 'sticker_chip.dart';

/// One row of today's plan.
///
/// Drag to reorder, tick to complete, and a play button that starts a focus
/// session on this task. **Ticking earns nothing** - it stamps the sticker, and
/// that separation is enforced all the way down in the engine.
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: title,
      checked: done,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        child: Row(
          children: [
            if (showGrip)
              Icon(Icons.drag_indicator, size: 16, color: tokens.inkFaint),
            // A 44pt hit target around a 19pt circle: the accessibility floor
            // is not negotiable, and this is the most-tapped control here.
            Semantics(
              button: true,
              label: done ? 'Mark not done' : 'Mark done',
              child: GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? tokens.states.solvent
                            : const Color(0x00000000),
                        border: Border.all(
                          color: done
                              ? tokens.states.solvent
                              : tokens.inkFaint,
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? Icon(Icons.check, size: 13, color: tokens.bg)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (stickerId != null) ...[
              StickerChip(stickerId: stickerId!, stamped: done),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.bodyLarge?.copyWith(
                      color: done ? tokens.inkFaint : tokens.ink,
                      decoration:
                          done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: tokens.inkFaint,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: text.labelMedium),
                ],
              ),
            ),
            if (estimateMinutes != null) ...[
              const SizedBox(width: 8),
              Text('${estimateMinutes}m', style: text.labelMedium),
            ],
            if (onStartFocus != null) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Start a focus session on $title',
                child: GestureDetector(
                  onTap: onStartFocus,
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
