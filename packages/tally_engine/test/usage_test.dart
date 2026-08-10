import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

const tiktok = 'com.zhiliaoapp.musically';
const insta = 'com.instagram.android';
const self = 'com.jr.tally';

DateTime at(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 8, 11, hour, minute);

UsageEvent resumed(String p, DateTime t) =>
    UsageEvent(packageName: p, at: t, type: UsageEventType.resumed);

UsageEvent paused(String p, DateTime t) =>
    UsageEvent(packageName: p, at: t, type: UsageEventType.paused);

UsageEvent screenOff(DateTime t) =>
    UsageEvent(packageName: '', at: t, type: UsageEventType.screenOff);

void main() {
  group('buildSpans', () {
    test('pairs a clean resume and pause', () {
      final spans = buildSpans(
        [resumed(tiktok, at(10)), paused(tiktok, at(10, 20))],
        streamEnd: at(11),
      );
      expect(spans, hasLength(1));
      expect(spans.single.seconds, 20 * 60);
    });

    test('closes a resume with no pause at the end of the stream', () {
      // The process was killed, so the pause never arrived. This is normal.
      final spans = buildSpans([resumed(tiktok, at(10))], streamEnd: at(10, 30));
      expect(spans.single.seconds, 30 * 60);
    });

    test('ignores a pause with no resume', () {
      // The query window began mid-session.
      expect(buildSpans([paused(tiktok, at(10))], streamEnd: at(11)), isEmpty);
    });

    test('a second resume closes the first span', () {
      final spans = buildSpans(
        [
          resumed(tiktok, at(10)),
          resumed(tiktok, at(10, 10)),
          paused(tiktok, at(10, 25)),
        ],
        streamEnd: at(11),
      );
      expect(spans.map((s) => s.seconds), [10 * 60, 15 * 60]);
    });

    test('screen off closes every open span', () {
      final spans = buildSpans(
        [
          resumed(tiktok, at(10)),
          resumed(insta, at(10, 5)),
          screenOff(at(10, 10)),
        ],
        streamEnd: at(11),
      );
      expect(spans, hasLength(2));
      expect(spans.every((s) => s.end == at(10, 10)), isTrue);
    });

    test('sorts input defensively, because event order is not guaranteed', () {
      final spans = buildSpans(
        [paused(tiktok, at(10, 20)), resumed(tiktok, at(10))],
        streamEnd: at(11),
      );
      expect(spans.single.seconds, 20 * 60);
    });

    test('drops zero-length spans', () {
      final spans = buildSpans(
        [resumed(tiktok, at(10)), paused(tiktok, at(10))],
        streamEnd: at(11),
      );
      expect(spans, isEmpty);
    });
  });

  group('mergeOverlapping', () {
    test('two apps in the same minute cost one minute, not two', () {
      // Picture-in-picture: YouTube over Instagram. A minute of the user's life
      // is one minute however many apps were on screen.
      final merged = mergeOverlapping([
        UsageSpan(packageName: tiktok, start: at(10), end: at(10, 30)),
        UsageSpan(packageName: insta, start: at(10, 10), end: at(10, 20)),
      ]);
      expect(merged, hasLength(1));
      expect(merged.single.seconds, 30 * 60);
    });

    test('extends the window when the second span runs longer', () {
      final merged = mergeOverlapping([
        UsageSpan(packageName: tiktok, start: at(10), end: at(10, 30)),
        UsageSpan(packageName: insta, start: at(10, 20), end: at(10, 50)),
      ]);
      expect(merged.single.seconds, 50 * 60);
    });

    test('keeps genuinely separate spans separate', () {
      final merged = mergeOverlapping([
        UsageSpan(packageName: tiktok, start: at(10), end: at(10, 10)),
        UsageSpan(packageName: insta, start: at(11), end: at(11, 10)),
      ]);
      expect(merged, hasLength(2));
    });

    test('touching spans merge rather than double counting the boundary', () {
      final merged = mergeOverlapping([
        UsageSpan(packageName: tiktok, start: at(10), end: at(10, 10)),
        UsageSpan(packageName: insta, start: at(10, 10), end: at(10, 20)),
      ]);
      expect(merged, hasLength(1));
      expect(merged.single.seconds, 20 * 60);
    });

    test('an empty list stays empty', () {
      expect(mergeOverlapping(const []), isEmpty);
    });
  });

  group('billableSpend', () {
    final watched = [
      WatchedApp(packageName: tiktok, addedAt: at(0)),
      WatchedApp(packageName: insta, addedAt: at(0)),
    ];

    test('drops apps the user never asked to watch', () {
      final result = billableSpend(
        [UsageSpan(packageName: 'com.bank.app', start: at(10), end: at(10, 30))],
        watched: watched,
        selfPackage: self,
      );
      expect(result, isEmpty);
    });

    test('never bills Tally for watching itself', () {
      // Excluded explicitly rather than by omission: relying on the user not to
      // add it is not a rule.
      final result = billableSpend(
        [UsageSpan(packageName: self, start: at(10), end: at(11))],
        watched: [...watched, WatchedApp(packageName: self, addedAt: at(0))],
        selfPackage: self,
      );
      expect(result, isEmpty);
    });

    test('removing an app stops future counting from that moment only', () {
      final removed = [
        WatchedApp(packageName: tiktok, addedAt: at(0), removedAt: at(10, 30)),
      ];
      final result = billableSpend(
        [UsageSpan(packageName: tiktok, start: at(10), end: at(11))],
        watched: removed,
        selfPackage: self,
      );
      // The half hour before removal is still billed, and it stays on past
      // statements. Only the future stops.
      expect(result.single.seconds, 30 * 60);
    });

    test('spend before an app was added is not billed retroactively', () {
      final late = [WatchedApp(packageName: tiktok, addedAt: at(10, 30))];
      final result = billableSpend(
        [UsageSpan(packageName: tiktok, start: at(10), end: at(11))],
        watched: late,
        selfPackage: self,
      );
      expect(result.single.seconds, 30 * 60);
      expect(result.single.start, at(10, 30));
    });

    test('overlapping watched apps are merged, not summed', () {
      final result = billableSpend(
        [
          UsageSpan(packageName: tiktok, start: at(10), end: at(10, 30)),
          UsageSpan(packageName: insta, start: at(10, 5), end: at(10, 25)),
        ],
        watched: watched,
        selfPackage: self,
      );
      expect(result.single.seconds, 30 * 60);
    });
  });
}
