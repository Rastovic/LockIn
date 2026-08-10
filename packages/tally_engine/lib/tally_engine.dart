/// The Tally ledger: focus earns minutes, scrolling spends them.
///
/// **Pure Dart on purpose.** This package has no Flutter dependency and no
/// plugin dependency, so the rule "the engine imports nothing platform-specific,
/// ever" is structural rather than remembered - it cannot be broken by accident.
/// Android supplies spend as [UsageSpan]s from `UsageStatsManager`; iOS, which
/// has no equivalent API, will supply coarser spans built from
/// `DeviceActivityMonitor` threshold callbacks. Neither is visible from here.
library;

export 'src/ledger_engine.dart';
export 'src/ledger_result.dart';
export 'src/session.dart';
export 'src/settings.dart';
export 'src/usage.dart';
