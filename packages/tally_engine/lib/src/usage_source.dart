import 'usage.dart';

/// Where spend comes from.
///
/// **Shaped around the question, not around Android's answer.** It asks "what
/// did this user spend, and which apps can I offer" rather than exposing
/// `queryEvents`, because iOS cannot answer the second question at all and an
/// interface shaped like `UsageStatsManager` would have to be torn up to add
/// it. See rule 3 in `00-foundation/CROSS-PLATFORM.md`.
///
/// Android returns real spans from `UsageStatsManager`. iOS, which has no
/// equivalent API, will return coarse spans built from `DeviceActivityMonitor`
/// threshold crossings. Neither is visible to [LedgerEngine], which takes
/// [UsageSpan]s and nothing else.
abstract interface class UsageSource {
  /// Whether the OS will hand over usage data.
  Future<UsageAccess> access();

  /// Opens the system screen where the user grants it.
  ///
  /// Usage access is a **special app access**, not a runtime permission: there
  /// is no in-app dialog, so the app has to send the user to Settings and then
  /// check on return.
  Future<void> requestAccess();

  /// Billable spans between two instants, already merged.
  ///
  /// Merged by the source because overlapping apps must cost one minute rather
  /// than two, and doing it here means every implementation owes the same
  /// guarantee.
  Future<List<UsageSpan>> spans({
    required DateTime from,
    required DateTime to,
    required List<String> packages,
  });

  /// Apps the user could choose to watch.
  ///
  /// [recentDays] of usage is attached so the picker can sort the worst
  /// offenders to the top, which makes the choice informed instead of guessed.
  Future<List<InstalledApp>> installedApps({int recentDays = 7});
}

/// Whether usage data is available.
enum UsageAccess {
  granted,

  /// Not granted. **The app must stay usable**: the plan still works, the
  /// timer still earns, and only the spending side is dark.
  denied,

  /// The device has no usage API at all, or it was removed by the OEM.
  unavailable,
}

/// An app on the device, with what it cost the user lately.
final class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    required this.recentSeconds,
    this.isSystem = false,
  });

  final String packageName;
  final String label;

  /// Foreground seconds over the recent window. The number that makes the
  /// watched-app picker worth opening.
  final int recentSeconds;

  final bool isSystem;

  int get recentMinutes => (recentSeconds / 60).round();
}

/// A [UsageSource] that returns whatever it was given.
///
/// Lets the whole app, including the reconcile loop, be exercised without a
/// device.
final class FakeUsageSource implements UsageSource {
  FakeUsageSource({
    this.spansToReturn = const [],
    this.apps = const [],
    this.accessState = UsageAccess.granted,
  });

  List<UsageSpan> spansToReturn;
  List<InstalledApp> apps;
  UsageAccess accessState;

  int requestCount = 0;

  @override
  Future<UsageAccess> access() async => accessState;

  @override
  Future<void> requestAccess() async => requestCount++;

  @override
  Future<List<UsageSpan>> spans({
    required DateTime from,
    required DateTime to,
    required List<String> packages,
  }) async {
    final wanted = packages.toSet();
    return [
      for (final span in spansToReturn)
        if (wanted.contains(span.packageName))
          if (span.clampTo(from, to) case final clamped?) clamped,
    ];
  }

  @override
  Future<List<InstalledApp>> installedApps({int recentDays = 7}) async => apps;
}
