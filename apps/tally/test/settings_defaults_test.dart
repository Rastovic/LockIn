import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install grants nothing', () async {
    // The point of the default: every minute of scrolling is one that was
    // focused for, from the first day.
    final db = TallyDatabase(NativeDatabase.memory());
    final c = TallyController(
      db: db,
      installId: install,
      settings: await TallyController.loadSettings(db),
      clock: () => DateTime.utc(2026, 8, 14, 10),
    );
    await c.load();
    expect(c.settings.dailyAllowanceMinutes, 0);
    expect(c.balanceModel.allowanceSeconds, 0);
  });

  test('a stored allowance wins over the default, as it must', () async {
    // Not a bug, and worth pinning: a value the user chose has to survive a
    // change to what the app ships with. It also means an install that saved
    // 30 before the default moved still has 30, and only Settings can change
    // that - the app must never quietly rewrite a number someone picked.
    final db = TallyDatabase(NativeDatabase.memory());
    final c = TallyController(
      db: db,
      installId: install,
      clock: () => DateTime.utc(2026, 8, 14, 10),
    );
    await c.load();
    await c.updateSettings(
      const LedgerSettings(dailyAllowanceMinutes: 30),
    );

    // Exactly what main() does on launch: read the stored settings first,
    // then build the controller with them. A test that constructs the
    // controller directly is testing a path the app never takes.
    final restored = await TallyController.loadSettings(db);
    final reopened = TallyController(
      db: db,
      installId: install,
      settings: restored,
      clock: () => DateTime.utc(2026, 8, 15, 10),
    );
    await reopened.load();
    expect(reopened.settings.dailyAllowanceMinutes, 30);
  });
}
