import 'dart:convert';
import 'dart:io';

import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

/// The shipped library, checked as content rather than as code.
///
/// The tone rules in the plan are strict and easy to erode one well-meaning
/// edit at a time, so they are mechanised here: plain and factual, a friend
/// with a spreadsheet rather than a coach, and **zero motivational quotes**.
void main() {
  final json = jsonDecode(
    File('assets/library_v1.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final parsed = parseLibrary(json);
  final items = parsed.items;

  group('the asset loads', () {
    test('every item parses', () {
      expect(parsed.skipped, isEmpty);
      expect(parsed.version, 1);
    });

    test('there are about forty items', () {
      expect(items.length, 40);
    });

    test('ids are unique', () {
      expect(items.map((i) => i.id).toSet(), hasLength(items.length));
    });

    test('every category is represented, none dominates', () {
      final byCategory = <LibraryCategory, int>{};
      for (final item in items) {
        byCategory.update(item.category, (v) => v + 1, ifAbsent: () => 1);
      }
      expect(byCategory.keys.toSet(), LibraryCategory.values.toSet());
      for (final count in byCategory.values) {
        expect(count, greaterThanOrEqualTo(5));
      }
    });

    test('a malformed entry costs one item, not the library', () {
      // Same reasoning as the archive reader: never crash on launch over one
      // bad row.
      final broken = parseLibrary({
        'version': 1,
        'items': [
          {'id': 'good', 'title': 'x', 'category': 'home', 'minutes': 10,
              'why': 'A reason.'},
          {'id': 'bad', 'title': 'x', 'category': 'nonsense', 'minutes': 10,
              'why': 'A reason.'},
          'not an object',
        ],
      });
      expect(broken.items.map((i) => i.id), ['good']);
      expect(broken.skipped, hasLength(2));
    });
  });

  group('the generated copy matches the source', () {
    test('same count, same ids, same copy', () {
      // The JSON is the editable source and the Dart is what ships. Drift
      // between them would mean an edit that never reached a user, so it is
      // guarded rather than remembered.
      expect(shippedLibrary.length, items.length);
      expect(libraryVersion, parsed.version);
      for (var i = 0; i < items.length; i++) {
        expect(shippedLibrary[i].id, items[i].id);
        expect(shippedLibrary[i].why, items[i].why);
        expect(shippedLibrary[i].minutes, items[i].minutes);
        expect(shippedLibrary[i].phoneDown, items[i].phoneDown);
        expect(shippedLibrary[i].stickerId, items[i].stickerId);
      }
    });
  });

  group('the shape of an item', () {
    test('every estimate is a real, finishable length', () {
      for (final item in items) {
        expect(item.minutes, greaterThanOrEqualTo(5), reason: item.id);
        expect(item.minutes, lessThanOrEqualTo(30), reason: item.id);
      }
    });

    test('nothing is under the five minute earning floor', () {
      // An item that cannot earn is an item that teaches the user the timer
      // does not work.
      const settings = LedgerSettings();
      for (final item in items) {
        expect(
          item.minutes,
          greaterThanOrEqualTo(settings.minEarnBlockMinutes),
          reason: item.id,
        );
      }
    });

    test('every sticker names one that actually exists', () {
      final known = {for (final s in StickerCatalog.all) s.id};
      for (final item in items) {
        if (item.stickerId == null) continue;
        expect(known, contains(item.stickerId), reason: item.id);
      }
    });

    test('every sticker used is a base one the user always has', () {
      // A suggested task wearing a locked sticker would show an empty square on
      // day one, which reads as a broken app rather than as something to earn.
      final base = {for (final s in StickerCatalog.base) s.id};
      for (final item in items) {
        if (item.stickerId == null) continue;
        expect(base, contains(item.stickerId), reason: item.id);
      }
    });

    test('there are enough phone-down items to offer one weekly', () {
      // The picker prefers a phone-down item on one day of each week, and the
      // 30 day repeat window means a handful is not enough.
      final phoneDown = items.where((i) => i.phoneDown).toList();
      expect(phoneDown.length, greaterThanOrEqualTo(5));
    });

    test('phone-down items are ones you can genuinely do with the screen off',
        () {
      // Screen-off is verified from screen state, so an item needing the phone
      // would silently fail its own bonus and look like a bug.
      const screenBound = ['email', 'subscription', 'balance', 'update',
          'appointment', 'back up'];
      for (final item in items.where((i) => i.phoneDown)) {
        for (final word in screenBound) {
          expect(
            item.title.toLowerCase(),
            isNot(contains(word)),
            reason: '${item.id} is phone-down but sounds screen-bound',
          );
        }
      }
    });
  });

  group('the tone rules, mechanised', () {
    test('every reason is exactly one sentence', () {
      for (final item in items) {
        final endings = RegExp(r'[.!?]').allMatches(item.why).length;
        expect(endings, 1, reason: '${item.id}: "${item.why}"');
        expect(item.why.trim(), endsWith('.'), reason: item.id);
      }
    });

    test('no exclamation marks anywhere', () {
      // Settled decision 3: plain and factual, no exclamation marks.
      for (final item in items) {
        expect(item.why, isNot(contains('!')), reason: item.id);
        expect(item.title, isNot(contains('!')), reason: item.id);
      }
    });

    test('no self-help vocabulary', () {
      // The library "is not a motivational quote engine and it ships zero
      // quotes". This is the test that keeps it that way through later edits.
      const banned = [
        'you can do',
        "you've got this",
        'you have got this',
        'believe in yourself',
        'crush it',
        'smash it',
        'journey',
        'mindset',
        'unlock your',
        'best self',
        'level up',
        'game changer',
        'transform your life',
        'no excuses',
        'just do it',
        'small wins',
        'momentum builds',
      ];
      for (final item in items) {
        final text = '${item.title} ${item.why}'.toLowerCase();
        for (final phrase in banned) {
          expect(text, isNot(contains(phrase)), reason: '${item.id}: $phrase');
        }
      }
    });

    test('no guilt', () {
      // A friend with a spreadsheet does not tell you that you should have.
      const shaming = ['you should have', 'you failed', 'lazy', 'shame',
          'stop making excuses', 'you keep failing'];
      for (final item in items) {
        final text = '${item.title} ${item.why}'.toLowerCase();
        for (final phrase in shaming) {
          expect(text, isNot(contains(phrase)), reason: '${item.id}: $phrase');
        }
      }
    });

    test('reasons state a mechanism rather than an instruction', () {
      // A "why" that repeats the task is wasted words. Each one must explain
      // something the title does not already say, so it has to be long enough
      // to carry a because.
      for (final item in items) {
        expect(item.why.length, greaterThan(45), reason: item.id);
        expect(item.why.length, lessThan(140), reason: '${item.id} is a speech');
      }
    });

    test('titles are short enough for one line on a phone', () {
      for (final item in items) {
        expect(item.title.length, lessThanOrEqualTo(40), reason: item.id);
        expect(item.title.trim(), item.title, reason: item.id);
      }
    });

    test('no reason begins by addressing the reader', () {
      // "You should..." is coaching. The numbers carry the message.
      for (final item in items) {
        expect(
          item.why.toLowerCase(),
          isNot(startsWith('you ')),
          reason: '${item.id}: "${item.why}"',
        );
      }
    });

    test('every reason is distinct', () {
      // Two items sharing a reason means at least one of them was padding.
      expect(items.map((i) => i.why).toSet(), hasLength(items.length));
    });
  });

  group('the library drives the picker', () {
    test('a year of suggestions never runs dry', () {
      const picker = SuggestionPicker();
      var day = '2026-01-01';
      var offered = 0;
      final history = <SuggestionRecord>[];

      for (var i = 0; i < 365; i++) {
        final item = picker.suggestionFor(
          dayKey: day,
          installId: '018f2c00-aaaa-7000-8000-000000000001',
          library: items,
          history: history,
        );
        if (item != null) {
          offered++;
          history.add(
            SuggestionRecord(
              itemId: item.id,
              dayKey: day,
              outcome: SuggestionOutcome.offered,
            ),
          );
        }
        final parts = day.split('-').map(int.parse).toList();
        final next = DateTime.utc(parts[0], parts[1], parts[2] + 1);
        day = '${next.year.toString().padLeft(4, '0')}-'
            '${next.month.toString().padLeft(2, '0')}-'
            '${next.day.toString().padLeft(2, '0')}';
      }

      // 40 items on a 30 day repeat window comfortably covers a year, and this
      // is what proves the library is large enough for the rule it is used
      // under.
      expect(offered, 365);
    });
  });
}
