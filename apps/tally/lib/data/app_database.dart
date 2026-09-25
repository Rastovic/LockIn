import 'dart:convert';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:tally_ui/tally_ui.dart' show BlockMode, TallyTheme;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
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

/// A focus block that is still running.
///
/// Held in preferences rather than the database because it is transient device
/// state rather than history: a block in progress on this phone means nothing
/// on another one, and it must not travel in a backup.
///
/// It is persisted at all because the wall-clock design survives backgrounding
/// but not the OS reclaiming the process, and on a cheap phone that happens
/// constantly. Losing a 45 minute block because Android wanted the memory is
/// the worst failure this app has: the time really was spent.
final class FocusStore {
  const FocusStore._();

  static const _key = 'tally.focus';

  static Future<void> save(FocusRun? run) async {
    final prefs = await SharedPreferences.getInstance();
    if (run == null || !run.isRunning) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode({
        'id': run.id,
        'startedAt': run.startedAt.millisecondsSinceEpoch,
        'plannedSeconds': run.planned.inSeconds,
        'extendedSeconds': run.extendedBy.inSeconds,
        'taskId': run.taskId,
        'phoneDown': run.phoneDownRequested,
        'unlocked': run.screenUnlockedDuringBlock,
        'pauses': [
          for (final pause in run.pauses)
            {
              'from': pause.from.millisecondsSinceEpoch,
              'to': pause.to?.millisecondsSinceEpoch,
            },
        ],
      }),
    );
  }

  /// [now] is the app's clock, not the wall clock.
  ///
  /// Passed in rather than read here because the twelve hour rule below is a
  /// real decision about the user's data, and a decision made against
  /// `DateTime.now()` cannot be tested: every test whose fixture is dated
  /// anything but today would have its restored block silently thrown away, and
  /// the test would be asserting the wall clock rather than the code.
  static Future<FocusRun?> load({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final started = DateTime.fromMillisecondsSinceEpoch(
        json['startedAt']! as int,
        isUtc: true,
      );

      // A block from days ago is not resumed. Something went wrong, and
      // presenting a stale countdown is worse than dropping it quietly.
      final asOf = now ?? DateTime.now().toUtc();
      if (asOf.difference(started).inHours > 12) {
        await prefs.remove(_key);
        return null;
      }

      return FocusRun(
        id: json['id']! as String,
        startedAt: started,
        planned: Duration(seconds: json['plannedSeconds']! as int),
        extendedBy: Duration(seconds: json['extendedSeconds'] as int? ?? 0),
        taskId: json['taskId'] as String?,
        phoneDownRequested: json['phoneDown'] as bool? ?? false,
        screenUnlockedDuringBlock: json['unlocked'] as bool? ?? false,
        pauses: [
          for (final pause in (json['pauses'] as List? ?? const []))
            if (pause is Map<String, Object?>)
              FocusPause(
                from: DateTime.fromMillisecondsSinceEpoch(
                  pause['from']! as int,
                  isUtc: true,
                ),
                to: pause['to'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        pause['to']! as int,
                        isUtc: true,
                      ),
              ),
        ],
      );
    } on Object {
      // A malformed record costs the block, never a crash on launch.
      await prefs.remove(_key);
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// What Digital Wellbeing said, as the user read it off.
///
/// Preferences rather than the database, and deliberately **not** in a backup:
/// this is a measurement of *this phone* against *this phone's* own counter.
/// Carried to a new device it would compare LockIn's numbers against readings
/// taken on hardware that is no longer involved, which is worse than having no
/// reading at all. Same reasoning that keeps `usage_checkpoints` local.
final class AccuracyReports {
  const AccuracyReports._();

  static String _key(String dayKey, String packageName) =>
      'tally.accuracy.$dayKey.$packageName';

  static Future<Map<String, int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getKeys())
        if (key.startsWith('tally.accuracy.'))
          key.substring('tally.accuracy.'.length): prefs.getInt(key) ?? 0,
    };
  }

  static Future<void> save(
    String dayKey,
    String packageName,
    int? minutes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(dayKey, packageName);
    // A negative reading is a typo, not a measurement, and storing it would
    // put a nonsense difference on screen.
    if (minutes == null || minutes < 0) {
      await prefs.remove(key);
      return;
    }
    await prefs.setInt(key, minutes);
  }
}

/// What happens when a watched app is opened with no minutes left.
///
/// A device preference rather than a ledger setting, like the theme: it only
/// does anything with this phone's accessibility switch on, so a restored
/// backup should not turn it on for a phone where that switch is off.
final class BlockPreference {
  const BlockPreference._();

  static const _key = 'tally.blockMode';

  static Future<BlockMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return BlockMode.values.firstWhere(
      (m) => m.name == prefs.getString(_key),
      orElse: () => BlockMode.off,
    );
  }

  static Future<void> save(BlockMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
