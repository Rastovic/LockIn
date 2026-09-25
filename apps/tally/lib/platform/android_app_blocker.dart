import 'dart:convert';

import 'package:flutter/services.dart';

/// Covers watched apps once the minutes run out, via an Android accessibility
/// service.
///
/// **Dart keeps the count, Android only subtracts.** [push] hands over the
/// authoritative spendable balance with the instant the usage behind it was
/// read; the service takes watched-app time since then off it and blocks at
/// zero. No ledger rule lives in Kotlin, the same seam the widget uses.
///
/// Two switches, and both must be on: the one in LockIn, which is the user's
/// choice, and the system accessibility switch, which only the user can flip
/// in Settings.
final class AndroidAppBlocker {
  const AndroidAppBlocker({
    this.channel = const MethodChannel('tally/usage'),
  });

  final MethodChannel channel;

  /// Whether the accessibility service is switched on in system settings.
  Future<bool> isOn() async {
    try {
      return await channel.invokeMethod<bool>('blockerOn') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Sends the user to the accessibility settings screen.
  ///
  /// There is no in-app dialog for this, as with usage access, so the caller
  /// re-checks [isOn] on return.
  Future<void> openSettings() async {
    try {
      await channel.invokeMethod<void>('openBlockerSettings');
    } on MissingPluginException {
      // Not Android.
    } on PlatformException {
      // No accessibility screen on this device; the switch stays off.
    }
  }

  Future<void> push({
    required bool enabled,
    required bool hard,
    required List<String> packages,
    required int spendableSeconds,
    required DateTime asOf,
    required DateTime validUntil,
  }) async {
    try {
      await channel.invokeMethod<void>('updateBlocking', {
        'enabled': enabled,
        // False is remind: the page offers "Continue anyway".
        'hard': hard,
        'packages': jsonEncode(packages),
        'spendableSeconds': spendableSeconds,
        'asOfMillis': asOf.millisecondsSinceEpoch,
        // Past this the app may owe a fresh allowance. Android keeps
        // subtracting from the old figure, which only errs towards blocking,
        // and the block screen says opening LockIn refreshes it.
        'validUntilMillis': validUntil.millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      // Any platform that is not Android, including the web preview.
    } on PlatformException {
      // A blocker working from an older figure is a smaller problem than an
      // app that will not open.
    }
  }
}
