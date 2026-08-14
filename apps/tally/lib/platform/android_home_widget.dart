import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// Today's plan, pushed to the home screen.
///
/// **Dart resolves everything the widget shows.** The Kotlin side receives
/// finished strings - a title, a glyph, a done flag - and knows nothing about
/// stickers, habits, plan order or what makes a day. That is the same rule the
/// watcher follows with [BalanceSnapshot]: Android renders, Dart decides.
///
/// The widget is **read only**. Tapping it opens the app rather than ticking
/// anything, and that is a deliberate limit rather than an unfinished edge:
/// ticking from a widget means either a second writer to the ledger living in
/// Kotlin, or a background isolate opening the same SQLite file as the running
/// app. One duplicates the rules, the other risks the data. Neither is worth a
/// saved tap on a list you are about to open anyway.
final class AndroidHomeWidget {
  const AndroidHomeWidget({
    this.channel = const MethodChannel('tally/usage'),
  });

  final MethodChannel channel;

  /// How many rows the widget is given.
  ///
  /// It scrolls, so this is a transfer limit rather than a display one. Fifty
  /// is far past any real day and stops a runaway plan from putting a
  /// megabyte through a platform channel.
  static const maxRows = 50;

  Future<void> push({
    required TodayView view,
    required String dateLabel,
    required int spendableSeconds,
    required bool usageVisible,
    required DateTime validUntil,
  }) async {
    final rows = [
      for (final row in view.rows.take(maxRows))
        {
          'title': row.task.title,
          'done': row.entry.doneAt != null,
          // Resolved here. Kotlin never learns what a sticker id means.
          'glyph': stickerGlyphs[row.task.stickerId] ?? '',
        },
    ];

    try {
      await channel.invokeMethod<void>('updateTodayWidget', {
        'dateLabel': dateLabel,
        'rows': jsonEncode(rows),
        'doneCount': view.doneCount,
        'totalCount': view.rows.length,
        'spendableSeconds': spendableSeconds,
        // False when usage access was never granted, and the widget then says
        // nothing about minutes rather than showing a confident zero.
        'usageVisible': usageVisible,
        // When this plan stops being today's. Android cannot work that out:
        // the boundary is a setting, it defaults to 4am and it moves with the
        // timezone. Sending the answer keeps the day rule in one place and
        // leaves Kotlin with a single comparison.
        'validUntilMillis': validUntil.millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      // Any platform that is not Android, including the web preview.
    } on PlatformException {
      // A widget that fails to update is a stale widget, which is a far
      // smaller problem than an app that will not open.
    }
  }
}
