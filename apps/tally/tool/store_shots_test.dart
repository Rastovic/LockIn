// Play Store screenshots from the real LockIn screens and engines, on a
// made-up account: two weeks of plans, ticks and app usage. Nothing from a
// real phone. Run: flutter test tool/store_shots_test.dart
// Output: ~/Documents/apps/apps/13-tally/screenshots/
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/app/tally_app.dart';
import 'package:tally/data/tally_controller.dart';
import 'package:tally_data/tally_data.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

final out = '${Platform.environment['HOME']}/Documents/apps/apps/13-tally/screenshots';
final flutterRoot = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
const install = '018f2c00-aaaa-7000-8000-00000000demo';

Future<void> loadFonts() async {
  Future<ByteData> f(String p) => File(p).readAsBytes().then((b) => b.buffer.asByteData());
  final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['Thin', 'Light', 'Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(f('$dir/Roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(f('$dir/MaterialIcons-Regular.otf'))).load();
  // Task stickers are emoji. Phones have Noto Color Emoji; the test renderer
  // has no emoji at all. Pass its path in EMOJI_FONT (not kept in the repo).
  final emoji = Platform.environment['EMOJI_FONT'];
  if (emoji != null) await (FontLoader('NotoColorEmoji')..addFont(f(emoji))).load();
}

/// The shipping theme, plus emoji fallback for the renderer (see loadFonts).
ThemeData withEmoji(ThemeData t) => t.copyWith(
      textTheme: t.textTheme.apply(fontFamilyFallback: const ['NotoColorEmoji']),
    );

DateTime at(DateTime day, int h, [int m = 0]) => DateTime(day.year, day.month, day.day, h, m).toUtc();

void main() {
  testWidgets('LockIn store screenshots', (t) async {
    await t.runAsync(loadFonts);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'tally.onboarded': true,
      'tally.tipsSeen': [for (final tip in Tip.values) tip.name],
      'tally.firstRunMillis': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
    });
    t.view.physicalSize = const Size(1080, 2160);
    t.view.devicePixelRatio = 2.75;

    final today = DateTime.now();
    final day0 = DateTime(today.year, today.month, today.day);
    var clock = at(day0.subtract(const Duration(days: 14)), 8);
    const watched = ['com.instagram.android', 'com.zhiliaoapp.musically', 'com.google.android.youtube', 'com.reddit.frontpage'];
    final usage = FakeUsageSource(apps: const [
      InstalledApp(packageName: 'com.instagram.android', label: 'Instagram', recentSeconds: 4 * 3600),
      InstalledApp(packageName: 'com.zhiliaoapp.musically', label: 'TikTok', recentSeconds: 5 * 3600),
      InstalledApp(packageName: 'com.google.android.youtube', label: 'YouTube', recentSeconds: 3 * 3600),
      InstalledApp(packageName: 'com.reddit.frontpage', label: 'Reddit', recentSeconds: 2 * 3600),
      InstalledApp(packageName: 'com.netflix.mediaclient', label: 'Netflix', recentSeconds: 90 * 60),
      InstalledApp(packageName: 'com.whatsapp', label: 'WhatsApp', recentSeconds: 70 * 60),
      InstalledApp(packageName: 'com.google.android.apps.maps', label: 'Maps', recentSeconds: 20 * 60),
    ]);
    // Evenings of scrolling, a little less in the second week.
    final spans = <UsageSpan>[];
    for (var d = 14; d >= 0; d--) {
      final day = day0.subtract(Duration(days: d));
      final less = d < 7 ? 0.7 : 1.0;
      for (var i = 0; i < watched.length; i++) {
        final start = at(day, 12 + i * 2, 10 * ((d + i) % 5));
        final mins = ((10 + (d * 7 + i * 11) % 16) * less).round();
        if (d == 0 && start.isAfter(at(day, 15))) continue;
        spans.add(UsageSpan(packageName: watched[i], start: start, end: start.add(Duration(minutes: mins))));
      }
    }
    usage.spansToReturn = spans;

    final db = TallyDatabase(NativeDatabase.memory());
    TallyController ctl() => TallyController(db: db, installId: install, usageSource: usage, clock: () => clock);

    final setup = (await t.runAsync(() async {
      final c = ctl();
      await c.load();
      final ids = <String, String>{};
      Future<void> add(String key, TaskDraft d) async => ids[key] = (await c.createTask(d)).id;
      await add('gym', const TaskDraft(kind: TaskKind.habit, title: 'Gym', stickerId: 'gym', estimateMinutes: 45, habitWeekdays: {1, 3, 5}));
      await add('read', const TaskDraft(kind: TaskKind.habit, title: 'Read 20 pages', stickerId: 'read', estimateMinutes: 20, habitWeekdays: {1, 2, 3, 4, 5, 6, 7}));
      await add('piano', const TaskDraft(kind: TaskKind.habit, title: 'Piano practice', stickerId: 'music', estimateMinutes: 20, habitWeekdays: {2, 4, 6}));
      await add('walk', const TaskDraft(kind: TaskKind.habit, title: 'Walk outside', stickerId: 'walk', estimateMinutes: 30, habitWeekdays: {1, 2, 3, 4, 5, 6, 7}));
      await add('dentist', const TaskDraft(kind: TaskKind.oneoff, title: 'Book the dentist', stickerId: 'call', estimateMinutes: 5));
      await add('surface', const TaskDraft(kind: TaskKind.oneoff, title: 'Clear one surface', stickerId: 'cleaning', estimateMinutes: 10));
      await add('sub', const TaskDraft(kind: TaskKind.oneoff, title: 'Cancel one subscription', stickerId: 'money', estimateMinutes: 10));
      await add('tax', const TaskDraft(kind: TaskKind.dread, title: 'Start the tax return', stickerId: 'admin', estimateMinutes: 30));
      await add('plants', const TaskDraft(kind: TaskKind.quick, title: 'Water the plants', stickerId: 'plants', estimateMinutes: 5));
      await add('email', const TaskDraft(kind: TaskKind.oneoff, title: 'Reply to the landlord', stickerId: 'work', estimateMinutes: 10));
      await c.loadWatchable();
      for (final app in c.watchable.where((a) => watched.contains(a.packageName))) {
        await c.setWatching(app, true);
      }
      return ids;
    }))!;

    // Two weeks of days: plan in the morning, tick most of it by evening.
    for (var d = 13; d >= 1; d--) {
      final day = day0.subtract(Duration(days: d));
      await t.runAsync(() async {
        clock = at(day, 8);
        final c = ctl();
        await c.load();
        final wd = day.weekday;
        final plan = <String>[
          'read', 'walk',
          if ({1, 3, 5}.contains(wd)) 'gym',
          if ({2, 4, 6}.contains(wd)) 'piano',
        ];
        await c.addToToday([for (final k in plan) setup[k]!]);
        clock = at(day, 21);
        final c2 = ctl();
        await c2.load();
        var i = 0;
        for (final e in [...c2.plan]) {
          if ((d + i++) % 4 != 0) await c2.toggle(e);
        }
      });
    }
    // Today: planned, half done, a focus in hand.
    final c = (await t.runAsync(() async {
      clock = at(day0, 8);
      final m = ctl();
      await m.load();
      await m.addToToday([setup['read']!, setup['walk']!, setup['dentist']!, setup['surface']!, setup['plants']!,
        if ({1, 3, 5}.contains(day0.weekday)) setup['gym']! else setup['piano']!]);
      clock = at(day0, 15, 20);
      final c = ctl();
      await c.load();
      for (final e in [...c.plan].take(3)) {
        await c.toggle(e);
      }
      return c;
    }))!;

    final key = GlobalKey();
    Future<void> shot(String name) async {
      for (var i = 0; i < 12; i++) {
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2.75);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    Widget app() => RepaintBoundary(
      key: key,
      child: MaterialApp(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        theme: withEmoji(TallyThemeBuilder.build(TallyTheme.aurora, Brightness.light)),
        darkTheme: withEmoji(TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark)),
        themeMode: ThemeMode.dark,
        home: TallyApp(controller: c, theme: TallyTheme.aurora, themeMode: ThemeMode.dark, onTheme: (_, _) {}),
      ),
    );
    await t.pumpWidget(app());
    await shot('screen-1-today.png');
    for (final (label, file) in [('Tasks', 'screen-3-tasks.png'), ('Stats', 'screen-4-stats.png'), ('Settings', 'screen-6-settings.png')]) {
      await t.tap(find.text(label).last);
      await shot(file);
    }
    // Settings with the watched apps open: the point of the app.
    await t.tap(find.text('WATCHED APPS').first);
    await shot('screen-6-settings.png');
    await t.tap(find.text('Today').last);
    await shot('screen-1-today.png');
    // The balance: what was earned and spent today.
    await t.tap(find.textContaining('min left').first);
    await shot('screen-5-balance.png');
    await t.pumpWidget(app());
    await shot('screen-1-today.png');
    // A focus session running on the next task, seven minutes in.
    // The focus screen reads the wall clock, so the run starts 7:12 before it.
    clock = DateTime.now().toUtc().subtract(const Duration(minutes: 7, seconds: 12));
    await t.runAsync(() async => c.startFocus(taskId: setup['surface'], minutes: 25));
    await shot('screen-2-focus.png');
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() => db.close());
  });
}
