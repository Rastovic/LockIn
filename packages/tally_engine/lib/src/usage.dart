/// Turning raw OS usage events into spend.
///
/// The Android source is `UsageStatsManager.queryEvents`, which emits
/// `ACTIVITY_RESUMED` / `ACTIVITY_PAUSED` pairs. Those pairs are routinely
/// malformed: a resume with no pause because the process was killed, a pause
/// with no resume because the query window began mid-session, two resumes in a
/// row, and events that arrive out of order. **All of that is normal input, not
/// an error path.**
///
/// This file is deliberately platform-free. iOS has no equivalent API and will
/// report coarse threshold crossings instead, which the engine consumes through
/// the same [UsageSpan] type.
library;

/// What the OS reported about one app at one instant.
enum UsageEventType {
  /// The app came to the foreground.
  resumed,

  /// The app left the foreground.
  paused,

  /// The screen went off or the device locked.
  ///
  /// Ends every open span regardless of package: a watched app "in front"
  /// behind a locked screen is not being scrolled.
  screenOff,
}

/// One raw event from the platform.
final class UsageEvent implements Comparable<UsageEvent> {
  const UsageEvent({
    required this.packageName,
    required this.at,
    required this.type,
  });

  /// Empty for [UsageEventType.screenOff], which is not app-specific.
  final String packageName;

  final DateTime at;
  final UsageEventType type;

  @override
  int compareTo(UsageEvent other) => at.compareTo(other.at);

  @override
  String toString() => '${type.name}($packageName @ ${at.toIso8601String()})';
}

/// A closed interval during which one app was in the foreground.
final class UsageSpan {
  UsageSpan({
    required this.packageName,
    required this.start,
    required this.end,
  }) : assert(!end.isBefore(start), 'A span cannot end before it starts');

  final String packageName;
  final DateTime start;
  final DateTime end;

  int get seconds => end.difference(start).inSeconds;

  bool overlaps(UsageSpan other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  /// The part of this span inside `[from, to)`, or null when there is none.
  UsageSpan? clampTo(DateTime from, DateTime to) {
    final s = start.isAfter(from) ? start : from;
    final e = end.isBefore(to) ? end : to;
    if (!e.isAfter(s)) return null;
    return UsageSpan(packageName: packageName, start: s, end: e);
  }

  @override
  String toString() =>
      'UsageSpan($packageName ${start.toIso8601String()}..${end.toIso8601String()})';
}

/// An app the user chose to price, and the window it was watched for.
///
/// Removing an app is not destructive: [removedAt] stops future counting from
/// that moment only, and historical spend stays on past statements.
final class WatchedApp {
  const WatchedApp({
    required this.packageName,
    required this.addedAt,
    this.removedAt,
  });

  final String packageName;
  final DateTime addedAt;
  final DateTime? removedAt;

  bool isWatchedAt(DateTime instant) {
    if (instant.isBefore(addedAt)) return false;
    final removed = removedAt;
    return removed == null || instant.isBefore(removed);
  }

  /// The part of [span] that falls inside this app's watched window.
  UsageSpan? clampToWatchedWindow(UsageSpan span) =>
      span.clampTo(addedAt, removedAt ?? _farFuture);

  static final _farFuture = DateTime.utc(9999);
}

/// Pairs raw events into spans, tolerating every malformation the platform
/// produces.
///
/// Rules, all of which exist because real event streams break them:
/// - a resume with no matching pause is closed at [streamEnd]
/// - a second resume for the same package closes the first at the new instant
/// - a pause with no open resume is ignored rather than throwing
/// - a [UsageEventType.screenOff] closes every open span
/// - zero-length spans are dropped
/// - input is sorted defensively, because event order is not guaranteed
List<UsageSpan> buildSpans(
  List<UsageEvent> events, {
  required DateTime streamEnd,
}) {
  final sorted = [...events]..sort();
  final open = <String, DateTime>{};
  final spans = <UsageSpan>[];

  void close(String package, DateTime at) {
    final started = open.remove(package);
    if (started == null) return;
    if (!at.isAfter(started)) return;
    spans.add(UsageSpan(packageName: package, start: started, end: at));
  }

  for (final event in sorted) {
    switch (event.type) {
      case UsageEventType.resumed:
        // A resume while already open means the pause was lost. Close the old
        // span here rather than discarding either one.
        close(event.packageName, event.at);
        open[event.packageName] = event.at;
      case UsageEventType.paused:
        close(event.packageName, event.at);
      case UsageEventType.screenOff:
        for (final package in open.keys.toList()) {
          close(package, event.at);
        }
    }
  }

  for (final package in open.keys.toList()) {
    close(package, streamEnd);
  }

  spans.sort((a, b) => a.start.compareTo(b.start));
  return spans;
}

/// Reduces spans to the wall-clock intervals during which *any* of them was
/// running.
///
/// This is what stops double counting. Picture-in-picture puts two watched apps
/// in the foreground at once, and a minute spent with both open is still one
/// minute of the user's life. The union is charged, never the sum.
List<UsageSpan> mergeOverlapping(List<UsageSpan> spans) {
  if (spans.isEmpty) return const [];
  final sorted = [...spans]..sort((a, b) => a.start.compareTo(b.start));
  final merged = <UsageSpan>[];

  var currentStart = sorted.first.start;
  var currentEnd = sorted.first.end;
  var label = sorted.first.packageName;

  for (final span in sorted.skip(1)) {
    if (!span.start.isAfter(currentEnd)) {
      if (span.end.isAfter(currentEnd)) currentEnd = span.end;
    } else {
      merged.add(
        UsageSpan(packageName: label, start: currentStart, end: currentEnd),
      );
      currentStart = span.start;
      currentEnd = span.end;
      label = span.packageName;
    }
  }
  merged.add(
    UsageSpan(packageName: label, start: currentStart, end: currentEnd),
  );
  return merged;
}

/// The billable spend timeline.
///
/// Keeps only spans belonging to a watched app, inside that app's own watched
/// window, excluding [selfPackage], then merges what remains so overlapping
/// apps cost one minute rather than two.
///
/// [selfPackage] is excluded explicitly rather than by omission: Tally watching
/// itself is never billable, and relying on the user not to add it is not a
/// rule.
List<UsageSpan> billableSpend(
  List<UsageSpan> spans, {
  required List<WatchedApp> watched,
  required String selfPackage,
}) {
  final byPackage = <String, List<WatchedApp>>{};
  for (final app in watched) {
    if (app.packageName == selfPackage) continue;
    byPackage.putIfAbsent(app.packageName, () => []).add(app);
  }

  final kept = <UsageSpan>[];
  for (final span in spans) {
    if (span.packageName == selfPackage) continue;
    for (final app in byPackage[span.packageName] ?? const <WatchedApp>[]) {
      final clamped = app.clampToWatchedWindow(span);
      if (clamped != null) kept.add(clamped);
    }
  }
  return mergeOverlapping(kept);
}
