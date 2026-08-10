import 'package:vitals_core/vitals_core.dart';

/// A curated task the app offers, shipped as a versioned JSON asset.
///
/// An empty task list is the second-biggest reason a habit app dies, after
/// permissions. So the app arrives already knowing forty things worth doing.
///
/// **No network fetch, ever.** The library is an asset, versioned with the app.
final class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.minutes,
    required this.why,
    this.phoneDown = false,
    this.stickerId,
  });

  final String id;
  final String title;
  final LibraryCategory category;
  final int minutes;

  /// One sentence on why it works.
  ///
  /// **Must not sound like a self-help book.** This is the most user-visible
  /// writing in the app, and the library ships zero motivational quotes.
  final String why;

  /// Phone-down items are the discipline mechanic and pay 1.5x.
  ///
  /// Verifiable on Android from screen state alone: start the block, put the
  /// phone face down, and if the screen stays off the bonus lands. No new
  /// permission needed.
  final bool phoneDown;

  final String? stickerId;

  @override
  String toString() => 'LibraryItem($id, "$title", ${minutes}m)';
}

enum LibraryCategory {
  home,
  body,
  mind,
  admin,
  craft;

  static LibraryCategory? parse(String value) {
    for (final category in values) {
      if (category.name == value) return category;
    }
    return null;
  }
}

/// Parses the shipped library asset.
///
/// Pure Dart, so the same code reads the file in a test and the bundled asset
/// on either platform. The caller supplies the string; how it was obtained is
/// the app's problem, not the engine's.
///
/// Malformed items are **skipped rather than thrown**, on the same reasoning as
/// the archive reader: one bad entry should cost one suggestion, never the
/// whole library and never a crash on launch.
({List<LibraryItem> items, int version, List<String> skipped}) parseLibrary(
  Map<String, Object?> json,
) {
  final version = json['version'] as int? ?? 0;
  final raw = json['items'];
  if (raw is! List) {
    return (items: const [], version: version, skipped: const ['no items']);
  }

  final items = <LibraryItem>[];
  final skipped = <String>[];
  for (final entry in raw) {
    if (entry is! Map<String, Object?>) {
      skipped.add('not an object');
      continue;
    }
    final id = entry['id'];
    final title = entry['title'];
    final why = entry['why'];
    final minutes = entry['minutes'];
    final category = LibraryCategory.parse(entry['category'] as String? ?? '');

    if (id is! String ||
        title is! String ||
        why is! String ||
        minutes is! int ||
        category == null) {
      skipped.add(id is String ? id : 'unnamed entry');
      continue;
    }

    items.add(
      LibraryItem(
        id: id,
        title: title,
        category: category,
        minutes: minutes,
        why: why,
        phoneDown: entry['phoneDown'] as bool? ?? false,
        stickerId: entry['sticker'] as String?,
      ),
    );
  }
  return (items: items, version: version, skipped: skipped);
}

/// What happened the last time an item was offered.
enum SuggestionOutcome { offered, accepted, dismissed }

/// One day's suggestion and its fate.
final class SuggestionRecord {
  const SuggestionRecord({
    required this.itemId,
    required this.dayKey,
    required this.outcome,
  });

  final String itemId;
  final String dayKey;
  final SuggestionOutcome outcome;
}

/// Picks the day's single suggested task.
///
/// Deterministic from `(dayKey, installId)`, so the same device shows the same
/// suggestion all day however many times the app is reopened, and two devices
/// do not show the same one. Recomputed rather than stored, which is the same
/// rule the ledger and the sticker unlocks follow.
final class SuggestionPicker {
  const SuggestionPicker({this.repeatWindowDays = 30});

  /// How long an item stays suppressed after being offered or dismissed.
  final int repeatWindowDays;

  /// The suggestion for [dayKey], or null when nothing is eligible.
  ///
  /// Eligibility: not already a task the user added, and not offered or
  /// dismissed inside the repeat window. Once a week the pick prefers a
  /// phone-down item, because that is where the discipline actually lives.
  LibraryItem? suggestionFor({
    required String dayKey,
    required String installId,
    required List<LibraryItem> library,
    List<SuggestionRecord> history = const [],
    Set<String> addedItemIds = const {},
  }) {
    final suppressed = <String>{};
    for (final record in history) {
      if (record.outcome == SuggestionOutcome.accepted) {
        suppressed.add(record.itemId);
        continue;
      }
      final age = daysBetween(record.dayKey, dayKey);
      // A record dated in the future is a clock that moved backwards, not a
      // reason to crash.
      if (age >= 0 && age < repeatWindowDays) suppressed.add(record.itemId);
    }

    final eligible = library
        .where((i) => !suppressed.contains(i.id) && !addedItemIds.contains(i.id))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (eligible.isEmpty) return null;

    if (isPhoneDownDay(dayKey: dayKey, installId: installId)) {
      final phoneDown = eligible.where((i) => i.phoneDown).toList();
      if (phoneDown.isNotEmpty) return _pick(phoneDown, dayKey, installId);
    }
    return _pick(eligible, dayKey, installId);
  }

  /// True on one day of each ISO week, chosen per install.
  bool isPhoneDownDay({required String dayKey, required String installId}) {
    final date = parseDayKey(dayKey);
    if (date == null) {
      throw ArgumentError.value(dayKey, 'dayKey', 'Not a YYYY-MM-DD day key');
    }
    // Anchor on the week's Monday so the chosen day is stable all week.
    final monday = addDays(dayKey, -(date.weekday - 1));
    final chosen = (stableHash('$installId|$monday') % 7) + 1;
    return date.weekday == chosen;
  }

  LibraryItem _pick(List<LibraryItem> pool, String dayKey, String installId) =>
      pool[stableHash('$installId|$dayKey') % pool.length];
}

/// FNV-1a over the UTF-16 code units, masked to 32 bits.
///
/// **Deliberately not `String.hashCode`.** Dart makes no promise that
/// `hashCode` is stable across runs, platforms or SDK versions, and a
/// suggestion that changes when the user updates the app - or differs between
/// the app and its widget - is a bug that would be very hard to see. This is
/// the seed for everything that must look random and stay put.
int stableHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit & 0xff;
    hash = (hash * 0x01000193) & 0xffffffff;
    hash ^= (unit >> 8) & 0xff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}
