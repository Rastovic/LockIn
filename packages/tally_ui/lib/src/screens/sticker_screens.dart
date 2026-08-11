import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/sticker_chip.dart';

/// A month of stamps.
final class StickerSheetModel {
  const StickerSheetModel({
    required this.monthLabel,
    required this.stamps,
    required this.daysInMonth,
    required this.daysElapsed,
  });

  final String monthLabel;

  /// Every stamp earned this month, in the order they were earned.
  final List<StickerStamp> stamps;

  final int daysInMonth;

  /// How much of the month has happened, so an empty future is not read as a
  /// gap.
  final int daysElapsed;

  int get count => stamps.length;

  /// Days this month with at least one stamp.
  int get daysWithAny => stamps.map((s) => s.dayKey).toSet().length;
}

/// The sheet: a month as a page that fills with stamps.
///
/// **The report the second currency exists for.** A good month is visibly full.
/// There is no score and no target: the page is the feedback, and adding a
/// percentage would turn it into another number to fall short of.
class StickerSheetScreen extends StatelessWidget {
  const StickerSheetScreen({
    required this.model,
    this.onOpenCollection,
    super.key,
  });

  final StickerSheetModel model;
  final VoidCallback? onOpenCollection;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    // A page of cells, one per stamp, padded out to the month's shape so the
    // empty ones read as room left rather than as nothing there.
    final cells = model.daysInMonth + 4;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Row(
              children: [
                Text(model.monthLabel, style: text.headlineMedium),
                const Spacer(),
                Text(
                  '${model.count} stamped',
                  style: text.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              model.count == 0
                  ? 'Finish something with a sticker on it and it lands here.'
                  : 'One stamp for every task you finished.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < cells; i++)
                  if (i < model.stamps.length)
                    _Cell(stickerId: model.stamps[i].stickerId)
                  else
                    const _Cell(),
              ],
            ),
            const SizedBox(height: 22),
            if (model.daysWithAny > 0)
              Text(
                'Something finished on ${model.daysWithAny} of '
                '${model.daysElapsed} days so far.',
                style: text.bodyMedium,
              ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Open the collection',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onOpenCollection,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('The collection', style: text.bodyLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({this.stickerId});

  final String? stickerId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (stickerId == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.surfaceStrong),
        ),
      );
    }
    return StickerChip(stickerId: stickerId!, size: 40, stamped: true);
  }
}

/// The collection: all sixty, with every rule in plain words.
///
/// **No mystery unlocks.** A locked sticker shows what earns it, because this
/// app's voice is a friend with a spreadsheet and a friend with a spreadsheet
/// does not make you guess.
class StickerCollectionScreen extends StatelessWidget {
  const StickerCollectionScreen({
    required this.context_,
    this.onClose,
    super.key,
  });

  /// The derived history the unlock rules read.
  final UnlockContext context_;

  final VoidCallback? onClose;

  static const _engine = UnlockEngine();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final unlocked = _engine.unlockedIds(context_);
    final earned = StickerCatalog.unlockable
        .where((s) => unlocked.contains(s.id))
        .toList();
    final locked = _engine.locked(context_);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
              child: Row(
                children: [
                  if (onClose != null)
                    Semantics(
                      button: true,
                      label: 'Back',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onClose,
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
                  Text('The collection', style: text.headlineMedium),
                  const Spacer(),
                  Text(
                    '${earned.length} of ${StickerCatalog.unlockable.length}',
                    style: text.labelMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text('ALWAYS YOURS', style: text.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Twenty-four labels you can put on any task.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sticker in StickerCatalog.base)
                        StickerChip(stickerId: sticker.id, size: 40),
                    ],
                  ),
                  const SizedBox(height: 26),
                  if (earned.isNotEmpty) ...[
                    Text('EARNED', style: text.labelSmall),
                    const SizedBox(height: 12),
                    for (final sticker in earned)
                      _UnlockRow(sticker: sticker, unlocked: true),
                    const SizedBox(height: 20),
                  ],
                  Text('STILL TO EARN', style: text.labelSmall),
                  const SizedBox(height: 12),
                  for (final sticker in locked)
                    _UnlockRow(sticker: sticker, unlocked: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockRow extends StatelessWidget {
  const _UnlockRow({required this.sticker, required this.unlocked});

  final Sticker sticker;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // A locked sticker is a silhouette, not a blank: the shape is part of
          // what makes it worth earning.
          Opacity(
            opacity: unlocked ? 1 : 0.22,
            child: StickerChip(stickerId: sticker.id, size: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sticker.rule ?? '',
              style: text.bodyMedium?.copyWith(
                color: unlocked ? tokens.ink : tokens.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
