@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// Renders every screen state at phone size, in every theme.
///
/// These are the images a design decision is actually judged from. Run with
/// `flutter test --update-goldens --tags golden` to regenerate, then look at
/// `test/goldens/`.
///
/// **Goldens catch regressions, not ugliness.** They prove a change did not
/// move a pixel nobody meant to move; they cannot tell you the layout is wrong.
/// For that the app has to run - `flutter run -d chrome` from `apps/tally`.
/// Loads a real font so the goldens are readable.
///
/// `flutter test` ships a placeholder font that draws every glyph as a filled
/// box, which is fine for catching a moved pixel and useless for judging copy.
/// These images exist to be looked at, so they get real letterforms.
///
/// Falls back silently when the font is absent: a golden with block text is
/// still a valid regression baseline, and CI on another machine must not fail
/// over a missing system font.
Future<void> loadRealFonts() async {
  const candidates = [
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Helvetica.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    for (final family in ['Roboto', '.SF Pro Rounded', 'SF Pro Rounded']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
    }
    return;
  }
}

const planner = TodayPlanner();
const dayKey = '2026-08-11'; // a Tuesday
final now = DateTime.utc(2026, 8, 11, 9, 41);

Task task(
  String id,
  String title, {
  TaskKind kind = TaskKind.oneoff,
  String? sticker,
  int? estimate,
  Set<int> weekdays = const {},
  DateTime? created,
}) =>
    Task(
      id: id,
      kind: kind,
      title: title,
      createdAt: created ?? DateTime.utc(2026, 8, 1),
      stickerId: sticker,
      estimateMinutes: estimate,
      habitWeekdays: weekdays,
    );

final demoTasks = [
  task('surface', 'Clear one surface', sticker: 'cleaning', estimate: 10),
  task('gym', 'Gym', sticker: 'gym', estimate: 45),
  task('sub', 'Cancel one subscription', sticker: 'money', estimate: 10),
  task(
    'flat',
    'Clean the flat',
    kind: TaskKind.dread,
    sticker: 'cleaning',
    estimate: 30,
    created: DateTime.utc(2026, 7, 8),
  ),
  task('piano', 'Piano', kind: TaskKind.habit, sticker: 'music',
      estimate: 20, weekdays: const {2}),
];

List<PlanEntry> demoPlan() {
  var plan = planner.addToDay(
    dayKey: dayKey,
    plan: const [],
    taskIds: ['surface', 'gym', 'sub', 'flat'],
  );
  return planner
      .complete(
        plan: plan,
        entryId: plan[2].id,
        tasks: demoTasks,
        at: now,
        dayKey: dayKey,
      )
      .plan;
}

const suggestion = LibraryItem(
  id: 'mind_phone_away',
  title: 'Phone in another room',
  category: LibraryCategory.mind,
  minutes: 30,
  why: 'Distance works where willpower does not, because the phone has to be '
      'fetched.',
  phoneDown: true,
  stickerId: 'selfcare',
);

Widget phone(Widget child, TallyTheme theme, Brightness brightness) =>
    MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 800),
        devicePixelRatio: 1,
        padding: EdgeInsets.only(top: 44, bottom: 20),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TallyThemeBuilder.build(theme, brightness),
        home: child,
      ),
    );

Future<void> shoot(
  WidgetTester tester,
  String name,
  Widget screen,
  TallyTheme theme,
  Brightness brightness,
) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(phone(screen, theme, brightness));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

TodayScreen todayWith({
  required List<PlanEntry> plan,
  int spendable = 2520,
  int streak = 6,
  LibraryItem? item = suggestion,
  String? notice,
  List<Task>? tasks,
}) =>
    TodayScreen(
      model: TodayScreenModel(
        view: planner.buildToday(
          dayKey: dayKey,
          tasks: tasks ?? demoTasks,
          plan: plan,
          now: now,
        ),
        spendableSeconds: spendable,
        solvencyStreak: streak,
        dateLabel: 'Tue 11 August',
        suggestion: item,
        graceNotice: notice,
      ),
    );

void main() {
  setUpAll(loadRealFonts);

  group('Today, every theme', () {
    for (final theme in TallyTheme.values) {
      for (final brightness in Brightness.values) {
        final label = '${theme.name}-${brightness.name}';

        testWidgets('$label solvent', (tester) async {
          await shoot(
            tester,
            'today-$label-solvent',
            todayWith(plan: demoPlan()),
            theme,
            brightness,
          );
        });
      }
    }
  });

  group('Today, every state in Aurora', () {
    testWidgets('running low', (tester) async {
      await shoot(
        tester,
        'today-low',
        todayWith(plan: demoPlan(), spendable: 420),
        TallyTheme.aurora,
        Brightness.dark,
      );
    });

    testWidgets('borrowing, with the grace notice', (tester) async {
      await shoot(
        tester,
        'today-borrowing',
        todayWith(
          plan: demoPlan(),
          spendable: -1080,
          streak: 0,
          notice: 'Grace used at 21:38. Every minute since has been −1. '
              'Debt stops at −60, and tomorrow’s allowance clears it before '
              'it fills your balance.',
        ),
        TallyTheme.aurora,
        Brightness.dark,
      );
    });

    testWidgets('nothing planned', (tester) async {
      await shoot(
        tester,
        'today-empty',
        todayWith(plan: const [], item: null, tasks: const []),
        TallyTheme.aurora,
        Brightness.dark,
      );
    });

    testWidgets('everything done', (tester) async {
      // An empty day and an all-done day are different states, and the goldens
      // are where that difference is checked.
      var plan = planner.addToDay(
        dayKey: dayKey,
        plan: const [],
        taskIds: ['surface', 'gym', 'sub'],
      );
      for (final entry in [...plan]) {
        plan = planner
            .complete(
              plan: plan,
              entryId: entry.id,
              tasks: demoTasks,
              at: now,
              dayKey: dayKey,
            )
            .plan;
      }
      await shoot(
        tester,
        'today-all-done',
        todayWith(plan: plan),
        TallyTheme.aurora,
        Brightness.dark,
      );
    });
  });
}
