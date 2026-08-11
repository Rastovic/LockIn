import 'package:drift_flutter/drift_flutter.dart';
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
