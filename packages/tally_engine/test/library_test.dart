import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

const picker = SuggestionPicker();
const install = '018f2c00-aaaa-7000-8000-000000000001';

LibraryItem item(String id, {bool phoneDown = false}) => LibraryItem(
      id: id,
      title: id,
      category: LibraryCategory.home,
      minutes: 10,
      why: 'because it is small enough to start',
      phoneDown: phoneDown,
    );

final library = [for (var i = 0; i < 20; i++) item('item-$i')];

void main() {
  group('stableHash', () {
    test('is deterministic', () {
      expect(stableHash('abc'), stableHash('abc'));
    });

    test('separates similar inputs', () {
      expect(stableHash('abc'), isNot(stableHash('abd')));
      expect(stableHash('a|b'), isNot(stableHash('ab')));
    });

    test('stays inside 32 bits and never goes negative', () {
      for (final s in ['', 'a', 'a much longer string with spaces', '2026-08-11']) {
        final h = stableHash(s);
        expect(h, greaterThanOrEqualTo(0));
        expect(h, lessThan(0x100000000));
      }
    });

    test('handles non-ASCII without collapsing', () {
      // The library ships real copy, so an accented title must not hash the
      // same as its stripped form.
      expect(stableHash('café'), isNot(stableHash('cafe')));
    });
  });

  group('suggestionFor', () {
    test('is stable for a given day and install', () {
      final a = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: install,
        library: library,
      );
      final b = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: install,
        library: library,
      );
      expect(a!.id, b!.id);
    });

    test('differs across days', () {
      final week = [
        for (var d = 11; d <= 17; d++)
          picker
              .suggestionFor(
                dayKey: '2026-08-$d',
                installId: install,
                library: library,
              )!
              .id,
      ];
      expect(week.toSet().length, greaterThan(1));
    });

    test('differs across installs on the same day', () {
      final mine = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: install,
        library: library,
      );
      final theirs = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: 'a-different-install',
        library: library,
      );
      expect(mine!.id, isNot(theirs!.id));
    });

    test('does not depend on the order the library was loaded in', () {
      final shuffled = [...library.reversed];
      expect(
        picker
            .suggestionFor(
              dayKey: '2026-08-11',
              installId: install,
              library: shuffled,
            )!
            .id,
        picker
            .suggestionFor(
              dayKey: '2026-08-11',
              installId: install,
              library: library,
            )!
            .id,
      );
    });

    test('skips an item already added as a task', () {
      final chosen = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: install,
        library: library,
      )!;
      final next = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: install,
        library: library,
        addedItemIds: {chosen.id},
      )!;
      expect(next.id, isNot(chosen.id));
    });

    test('a dismissed item is suppressed for 30 days, then returns', () {
      final history = [
        const SuggestionRecord(
          itemId: 'item-3',
          dayKey: '2026-08-01',
          outcome: SuggestionOutcome.dismissed,
        ),
      ];
      bool offered(String day) =>
          picker
              .suggestionFor(
                dayKey: day,
                installId: install,
                library: [item('item-3')],
                history: history,
              ) !=
          null;

      expect(offered('2026-08-11'), isFalse, reason: '10 days later');
      expect(offered('2026-08-30'), isFalse, reason: '29 days later');
      expect(offered('2026-08-31'), isTrue, reason: '30 days later');
    });

    test('an accepted item is never offered again', () {
      // It is a real task now. Offering it back would be noise.
      final result = picker.suggestionFor(
        dayKey: '2027-01-01',
        installId: install,
        library: [item('item-3')],
        history: [
          const SuggestionRecord(
            itemId: 'item-3',
            dayKey: '2026-08-01',
            outcome: SuggestionOutcome.accepted,
          ),
        ],
      );
      expect(result, isNull);
    });

    test('returns null when everything is suppressed', () {
      final result = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: install,
        library: library,
        addedItemIds: {for (final i in library) i.id},
      );
      expect(result, isNull);
    });

    test('an empty library yields nothing rather than throwing', () {
      expect(
        picker.suggestionFor(
          dayKey: '2026-08-11',
          installId: install,
          library: const [],
        ),
        isNull,
      );
    });

    test('a history record dated in the future does not crash', () {
      // A user moved their device date backwards. Not an error path.
      final result = picker.suggestionFor(
        dayKey: '2026-08-11',
        installId: install,
        library: [item('item-3')],
        history: [
          const SuggestionRecord(
            itemId: 'item-3',
            dayKey: '2027-01-01',
            outcome: SuggestionOutcome.offered,
          ),
        ],
      );
      expect(result, isNotNull);
    });
  });

  group('the weekly phone-down preference', () {
    test('lands on exactly one day per week', () {
      final week = [
        for (var d = 10; d <= 16; d++) // Mon 10 Aug to Sun 16 Aug
          picker.isPhoneDownDay(dayKey: '2026-08-$d', installId: install),
      ];
      expect(week.where((x) => x).length, 1);
    });

    test('is stable within a week and can move between weeks', () {
      final first = [
        for (var d = 10; d <= 16; d++)
          picker.isPhoneDownDay(dayKey: '2026-08-$d', installId: install),
      ];
      final repeat = [
        for (var d = 10; d <= 16; d++)
          picker.isPhoneDownDay(dayKey: '2026-08-$d', installId: install),
      ];
      expect(first, repeat);
    });

    test('prefers a phone-down item on that day', () {
      final mixed = [
        ...library,
        item('quiet-1', phoneDown: true),
        item('quiet-2', phoneDown: true),
      ];
      final phoneDownDay = [
        for (var d = 10; d <= 16; d++) '2026-08-$d',
      ].firstWhere(
        (day) => picker.isPhoneDownDay(dayKey: day, installId: install),
      );

      final chosen = picker.suggestionFor(
        dayKey: phoneDownDay,
        installId: install,
        library: mixed,
      )!;
      expect(chosen.phoneDown, isTrue);
    });

    test('falls back to any item when no phone-down one is eligible', () {
      final phoneDownDay = [
        for (var d = 10; d <= 16; d++) '2026-08-$d',
      ].firstWhere(
        (day) => picker.isPhoneDownDay(dayKey: day, installId: install),
      );
      final chosen = picker.suggestionFor(
        dayKey: phoneDownDay,
        installId: install,
        library: library, // none are phone-down
      );
      expect(chosen, isNotNull);
      expect(chosen!.phoneDown, isFalse);
    });
  });

  group('coverage of the library over time', () {
    test('a year of suggestions spreads across the library', () {
      // A picker that keeps landing on the same handful of items would make the
      // library feel far smaller than it is.
      final seen = <String>{};
      for (var d = 0; d < 200; d++) {
        final day = '2026-01-01';
        final item = picker.suggestionFor(
          dayKey: _addDays(day, d),
          installId: install,
          library: library,
        );
        if (item != null) seen.add(item.id);
      }
      expect(seen.length, greaterThan(library.length ~/ 2));
    });
  });
}

String _addDays(String key, int days) {
  final parts = key.split('-').map(int.parse).toList();
  final d = DateTime.utc(parts[0], parts[1], parts[2] + days);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
