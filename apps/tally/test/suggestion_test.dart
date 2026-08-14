import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally_data/tally_data.dart';

/// The daily suggestion card.
///
/// Two bugs shipped together here. "Not now" was wired to an empty function,
/// so it wrote nothing and the same deterministic pick was rebuilt a moment
/// later - a button that visibly did nothing. And accepted items were matched
/// by comparing task UUIDs against library item ids, two id spaces that never
/// intersect, so accepting one never took it out of rotation either.
const install = '018f2c00-aaaa-7000-8000-000000000001';

TallyController build() => TallyController(
      db: TallyDatabase(NativeDatabase.memory()),
      installId: install,
      clock: () => DateTime.utc(2026, 8, 14, 10),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('not now replaces the suggestion with a different one', () async {
    final c = build();
    await c.load();

    final first = c.today.suggestion;
    expect(first, isNotNull);

    await c.dismissSuggestion(first!);
    final second = c.today.suggestion;

    expect(second, isNotNull, reason: 'one goes, another arrives');
    expect(second!.id, isNot(first.id));
  });

  test('a dismissed suggestion does not come back the same day', () async {
    final c = build();
    await c.load();

    final seen = <String>{};
    for (var i = 0; i < 5; i++) {
      final item = c.today.suggestion;
      expect(item, isNotNull, reason: 'the library does not run dry');
      expect(seen.add(item!.id), isTrue, reason: '${item.id} came back');
      await c.dismissSuggestion(item);
    }
  });

  test('accepting one plans it and offers a different one', () async {
    final c = build();
    await c.load();

    final first = c.today.suggestion!;
    await c.acceptSuggestion(first);

    expect(
      c.tasks.map((t) => t.title),
      contains(first.title),
      reason: 'it became a real task',
    );
    expect(c.plan, hasLength(1), reason: 'and it was planned into today');
    expect(c.today.suggestion?.id, isNot(first.id));
  });

  test('an accepted suggestion stays gone across a reload', () async {
    // Accepted items are suppressed forever, not for a window: the whole point
    // is that the app stops offering something you already took.
    final db = TallyDatabase(NativeDatabase.memory());
    final c = TallyController(
      db: db,
      installId: install,
      clock: () => DateTime.utc(2026, 8, 14, 10),
    );
    await c.load();
    final first = c.today.suggestion!;
    await c.acceptSuggestion(first);

    final reopened = TallyController(
      db: db,
      installId: install,
      clock: () => DateTime.utc(2026, 8, 20, 10),
    );
    await reopened.load();
    expect(reopened.today.suggestion?.id, isNot(first.id));
  });
}
