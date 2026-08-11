import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:tally_ui/tally_ui.dart' show TallyTheme;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally_data/tally_data.dart';
import 'package:vitals_core/vitals_core.dart';

/// Opens the database on the device.
///
/// One file, in the app's own documents directory, so Android's auto-backup can
/// take it and the user never has to think about where it lives.
TallyDatabase openTallyDatabase() =>
    TallyDatabase(driftDatabase(name: 'tally'));

/// The id every row written on this device is stamped with.
///
/// Generated once and kept. It is what tells a future merge which device said
/// what, so it must survive restarts - and it must **not** be regenerated on a
/// restore, or every row imported from the old phone would look like it came
/// from somewhere else.
final class InstallId {
  const InstallId._();

  static const _key = 'tally.installId';

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && Ids.isValid(existing)) return existing;

    final fresh = Ids.newId();
    await prefs.setString(_key, fresh);
    return fresh;
  }
}

/// Whether first-run onboarding has been finished.
///
/// Kept in preferences rather than the database, because it describes this
/// install rather than the user's data: someone restoring a backup onto a new
/// phone still needs to be walked through granting usage access there.
final class OnboardingState {
  const OnboardingState._();

  static const _key = 'tally.onboarded';

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

/// The chosen theme and brightness.
///
/// In preferences rather than the database because it describes this device's
/// look rather than the user's data. A restored backup should not repaint the
/// phone it landed on.
final class ThemePreference {
  const ThemePreference._();

  static const _themeKey = 'tally.theme';
  static const _modeKey = 'tally.themeMode';

  static Future<(TallyTheme, ThemeMode)> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = TallyTheme.values.firstWhere(
      (t) => t.name == prefs.getString(_themeKey),
      orElse: () => TallyTheme.aurora,
    );
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(_modeKey),
      orElse: () => ThemeMode.dark,
    );
    return (theme, mode);
  }

  static Future<void> save(TallyTheme theme, ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    await prefs.setString(_modeKey, mode.name);
  }
}
