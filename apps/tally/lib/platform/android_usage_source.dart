import 'package:flutter/services.dart';
import 'package:tally_engine/tally_engine.dart';

/// Usage from Android's `UsageStatsManager`, over one method channel.
///
/// **The only file in the app that knows Android exists.** Rule 1 of
/// `CROSS-PLATFORM.md`: platform branching lives in one implementation behind
/// an interface, never scattered through the UI. The iOS version becomes a
/// second implementation of [UsageSource] and no caller changes.
///
/// Every failure is answered rather than thrown. A tracker whose numbers vanish
/// because a channel call went wrong is worse than one that reports nothing:
/// the app must stay usable, and the plan still works even with the spending
/// side dark.
final class AndroidUsageSource implements UsageSource {
  const AndroidUsageSource({
    this.channel = const MethodChannel('tally/usage'),
  });

  final MethodChannel channel;

  @override
  Future<UsageAccess> access() async {
    try {
      final granted = await channel.invokeMethod<bool>('hasAccess');
      return (granted ?? false) ? UsageAccess.granted : UsageAccess.denied;
    } on MissingPluginException {
      // Running on a platform with no implementation: the web preview, or iOS
      // before its own source exists.
      return UsageAccess.unavailable;
    } on PlatformException {
      return UsageAccess.unavailable;
    }
  }

  @override
  Future<void> requestAccess() async {
    try {
      await channel.invokeMethod<void>('openAccessSettings');
    } on PlatformException {
      // Nothing to do: some devices have no usage-access screen at all, and
      // the caller already has to handle access staying denied.
    }
  }

  @override
  Future<List<UsageSpan>> spans({
    required DateTime from,
    required DateTime to,
    required List<String> packages,
  }) async {
    if (packages.isEmpty) return const [];
    try {
      final raw = await channel.invokeListMethod<Map<Object?, Object?>>(
        'spans',
        {
          'from': from.millisecondsSinceEpoch,
          'to': to.millisecondsSinceEpoch,
          'packages': packages,
        },
      );
      if (raw == null) return const [];

      final spans = <UsageSpan>[];
      for (final row in raw) {
        final package = row['packageName'];
        final start = row['start'];
        final end = row['end'];
        // A malformed row costs one row. The same rule the archive reader and
        // the library parser follow, for the same reason.
        if (package is! String || start is! int || end is! int) continue;
        if (end <= start) continue;
        spans.add(
          UsageSpan(
            packageName: package,
            start: DateTime.fromMillisecondsSinceEpoch(start, isUtc: true),
            end: DateTime.fromMillisecondsSinceEpoch(end, isUtc: true),
          ),
        );
      }
      return spans;
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  @override
  Future<List<InstalledApp>> installedApps({int recentDays = 7}) async {
    try {
      final raw = await channel.invokeListMethod<Map<Object?, Object?>>(
        'installedApps',
        {'recentDays': recentDays},
      );
      if (raw == null) return const [];

      final apps = <InstalledApp>[];
      for (final row in raw) {
        final package = row['packageName'];
        final label = row['label'];
        if (package is! String || label is! String) continue;
        apps.add(
          InstalledApp(
            packageName: package,
            label: label,
            recentSeconds: row['recentSeconds'] as int? ?? 0,
            isSystem: row['isSystem'] as bool? ?? false,
          ),
        );
      }
      return apps;
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }
}
