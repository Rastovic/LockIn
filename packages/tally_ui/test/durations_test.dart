import 'package:flutter_test/flutter_test.dart';
import 'package:tally_ui/tally_ui.dart';

/// The 66-vs-67 bug: the Statement floored the day's seconds while Insights
/// rounded them, so the same day showed two different totals depending on which
/// screen you were looking at.
void main() {
  group('minutes', () {
    test('shows only whole completed minutes', () {
      expect(wholeMinutes(0), 0);
      expect(wholeMinutes(59), 0);
      expect(wholeMinutes(60), 1);
      // 66m30s. Rounding calls this 67 and the app used to, on one screen.
      expect(wholeMinutes(3990), 66);
      expect(wholeMinutes(3999), 66);
    });

    test('never rounds a partial minute up into credit', () {
      // A session 59 seconds old has earned nothing. Saying "1 minute" would
      // be the app inventing time the user has not put in.
      expect(wholeMinutes(59), 0);
      expect(formatMinutes(59), '0');
    });

    test('floors a debt away from zero, never towards it', () {
      // Rounding a debt towards zero flatters the number, which is the one
      // thing this app must never do. 90 seconds owed reads as −2, not −1.
      expect(wholeMinutes(-90), -2);
      expect(wholeMinutes(-1), -1);
      expect(wholeMinutes(-60), -1);
      expect(formatMinutes(-120), '−2');
    });

    test('every formatter agrees on the same seconds', () {
      const seconds = 3990;
      expect(formatMinutes(seconds), '66');
      expect(formatDuration(seconds), '1h 06m');
      expect(formatClock(seconds), '1h06');
      // The whole point: one value, one minute count, three presentations.
      for (final s in [0, 59, 60, 3599, 3600, 3990, 86399]) {
        final n = wholeMinutes(s);
        expect(formatMinutes(s), '$n');
        expect(
          formatDuration(s),
          n < 60 ? '${n}m' : '${n ~/ 60}h ${(n % 60).toString().padLeft(2, '0')}m',
        );
      }
    });
  });
}
