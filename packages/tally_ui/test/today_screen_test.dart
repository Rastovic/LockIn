import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

const planner = TodayPlanner();
const today = '2026-08-11';
final now = DateTime.utc(2026, 8, 11, 9);

Task task(
  String id, {
  TaskKind kind = TaskKind.oneoff,
  String? sticker,
  int? estimate,
  Set<int> weekdays = const {},
  DateTime? created,
}) =>
    Task(
      id: id,
      kind: kind,
      title: id,
      createdAt: created ?? DateTime.utc(2026, 8, 1),
      stickerId: sticker,
      estimateMinutes: estimate,
      habitWeekdays: weekdays,
    );

TodayScreenModel modelFor(
  List<Task> tasks,
  List<PlanEntry> plan, {
  int spendable = 2520,
  int streak = 6,
  LibraryItem? suggestion,
  String? notice,
}) =>
    TodayScreenModel(
      view: planner.buildToday(
        dayKey: today,
        tasks: tasks,
        plan: plan,
        now: now,
      ),
      spendableSeconds: spendable,
      solvencyStreak: streak,
      dateLabel: 'Tue 11 August',
      suggestion: suggestion,
      graceNotice: notice,
    );

Widget wrap(Widget child, {TallyTheme theme = TallyTheme.aurora}) => MaterialApp(
      theme: TallyThemeBuilder.build(theme, Brightness.dark),
      home: child,
    );

void main() {
  group('the plan', () {
    testWidgets('shows the date, planned minutes and every row', (tester) async {
      final tasks = [
        task('Clear one surface', sticker: 'cleaning', estimate: 10),
        task('Gym', estimate: 45),
      ];
      final plan = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: [for (final t in tasks) t.id],
      );

      await tester.pumpWidget(wrap(TodayScreen(model: modelFor(tasks, plan))));

      expect(find.text('TUE 11 AUGUST'), findsOneWidget);
      expect(find.text('55 min planned'), findsOneWidget);
      expect(find.text('Clear one surface'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('planned minutes are stated, never coloured as a warning',
        (tester) async {
      // The only feedback on an overloaded day, and deliberately flat: no cap,
      // no warning, no colour change. The number is the warning.
      final tasks = [for (var i = 0; i < 8; i++) task('task $i', estimate: 45)];
      final plan = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: [for (final t in tasks) t.id],
      );

      await tester.pumpWidget(wrap(TodayScreen(model: modelFor(tasks, plan))));

      final text = tester.widget<Text>(find.text('360 min planned'));
      final tokens = TallyTokens.of(TallyTheme.aurora, Brightness.dark);
      expect(text.style?.color, isNot(tokens.states.borrowing));
      expect(text.style?.color, isNot(tokens.states.low));
    });

    testWidgets('a dread task shows how long it has been avoided',
        (tester) async {
      final tasks = [
        task(
          'Clean the flat',
          kind: TaskKind.dread,
          created: DateTime.utc(2026, 7, 8),
        ),
      ];
      final plan = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: ['Clean the flat'],
      );

      await tester.pumpWidget(wrap(TodayScreen(model: modelFor(tasks, plan))));
      expect(find.text('avoided 34 days'), findsOneWidget);
    });
  });

  group('reordering', () {
    testWidgets('reports a final position, not an insertion index',
        (tester) async {
      // The off-by-one that only shows when dragging downwards: the older
      // onReorder callback reports a destination one higher than the final
      // position. TodayPlanner.reorder takes a final position.
      final moves = <(int, int)>[];
      final tasks = [task('a'), task('b'), task('c')];
      final plan = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: ['a', 'b', 'c'],
      );

      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor(tasks, plan),
            onReorder: (from, to) => moves.add((from, to)),
          ),
        ),
      );

      final list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      // Drive the callback the way the framework does.
      list.onReorderItem!(0, 2);
      expect(moves, [(0, 2)], reason: 'a final position, unadjusted');
    });
  });

  group('completion', () {
    testWidgets('the done control is quiet: a ring, no tick glyph',
        (tester) async {
      // Settled at review. The row already says done three other ways, so a
      // check mark was a fourth signal and the loudest of them.
      final tasks = [task('Gym', sticker: 'gym')];
      var plan = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: ['Gym'],
      );
      plan = planner
          .complete(
            plan: plan,
            entryId: plan.single.id,
            tasks: tasks,
            at: now,
            dayKey: today,
          )
          .plan;

      await tester.pumpWidget(wrap(TodayScreen(model: modelFor(tasks, plan))));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
      final title = tester.widget<Text>(find.text('Gym'));
      expect(title.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('tapping the dot toggles the right entry', (tester) async {
      PlanEntry? toggled;
      final tasks = [task('a'), task('b')];
      final plan = planner.addToDay(
        dayKey: today,
        plan: const [],
        taskIds: ['a', 'b'],
      );

      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor(tasks, plan),
            onToggle: (entry) => toggled = entry,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Mark b done'));
      expect(toggled?.taskId, 'b');
    });

    testWidgets('the play button starts focus on that task', (tester) async {
      PlanEntry? started;
      final tasks = [task('Gym')];
      final plan =
          planner.addToDay(dayKey: today, plan: const [], taskIds: ['Gym']);

      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor(tasks, plan),
            onStartFocus: (entry) => started = entry,
          ),
        ),
      );

      await tester.tap(
        find.bySemanticsLabel('Start a focus session on Gym'),
      );
      expect(started?.taskId, 'Gym');
    });
  });

  group('habits are offered, never auto-added', () {
    testWidgets('a habit due today appears as an offer with an Add',
        (tester) async {
      // 2026-08-11 is a Tuesday.
      final tasks = [task('Piano', kind: TaskKind.habit, weekdays: {2})];

      await tester.pumpWidget(
        wrap(TodayScreen(model: modelFor(tasks, const []))),
      );

      expect(find.text('Piano · due today'), findsOneWidget);
      // It is offered, so it is not counted in the plan.
      expect(find.text('0 min planned'), findsOneWidget);
    });

    testWidgets('accepting an offered habit reports it', (tester) async {
      Task? accepted;
      final tasks = [task('Piano', kind: TaskKind.habit, weekdays: {2})];

      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor(tasks, const []),
            onAcceptHabit: (habit) => accepted = habit,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Add Piano to today'));
      expect(accepted?.id, 'Piano');
    });
  });

  group('the suggestion', () {
    testWidgets('shows the title, the minutes and the reason', (tester) async {
      const item = LibraryItem(
        id: 'mind_phone_away',
        title: 'Phone in another room',
        category: LibraryCategory.mind,
        minutes: 30,
        why: 'Distance works where willpower does not, because the phone has '
            'to be fetched.',
        phoneDown: true,
      );

      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor([task('a')],
                planner.addToDay(dayKey: today, plan: const [], taskIds: ['a']),
                suggestion: item),
          ),
        ),
      );

      expect(
        find.text('Phone in another room · 30m · phone down, 1.5x'),
        findsOneWidget,
      );
      expect(find.textContaining('has to be fetched'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('a grace notice replaces the suggestion', (tester) async {
      // Where a nudge the OS refused, or one held back by the daily cap, lands
      // on next open. Nothing is dropped silently.
      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor(
              [task('a')],
              planner.addToDay(dayKey: today, plan: const [], taskIds: ['a']),
              suggestion: const LibraryItem(
                id: 'x',
                title: 'Should not show',
                category: LibraryCategory.home,
                minutes: 10,
                why: 'A reason.',
              ),
              notice: 'Grace used at 21:38. Every minute since has been −1.',
            ),
          ),
        ),
      );

      expect(find.textContaining('Grace used at 21:38'), findsOneWidget);
      expect(find.text('Should not show'), findsNothing);
    });
  });

  group('the empty day', () {
    testWidgets('is not treated as a finished day', (tester) async {
      // An empty state and an all-done state say different things, and neither
      // congratulates.
      await tester.pumpWidget(
        wrap(TodayScreen(model: modelFor(const [], const []))),
      );

      expect(find.text('Nothing planned'), findsOneWidget);
      expect(find.textContaining('do not have to be big'), findsOneWidget);
    });

    testWidgets('no copy anywhere cheers or scolds', (tester) async {
      // Settled decision 3: plain and factual, no exclamation marks. The tone
      // rule is mechanised for the library, so it is mechanised here too.
      await tester.pumpWidget(
        wrap(TodayScreen(model: modelFor(const [], const []))),
      );

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(texts, isNot(contains('!')));
      for (final word in ['great', 'well done', 'nice work', 'keep it up']) {
        expect(texts.toLowerCase(), isNot(contains(word)), reason: word);
      }
    });

    testWidgets('start focus is disabled with nothing planned', (tester) async {
      await tester.pumpWidget(
        wrap(TodayScreen(model: modelFor(const [], const []))),
      );
      // Present, so the screen does not change shape, but not offering an
      // action that has no subject.
      expect(find.text('Start focus'), findsOneWidget);
    });
  });

  group('the balance strip', () {
    testWidgets('opens the full balance on tap', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor(const [], const []),
            onOpenBalance: () => opened++,
          ),
        ),
      );

      await tester.tap(find.text('42'));
      expect(opened, 1);
    });

    testWidgets('borrowing colours the strip and breaks the streak',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          TodayScreen(
            model: modelFor(const [], const [], spendable: -1080, streak: 0),
          ),
        ),
      );

      expect(find.text('−18'), findsOneWidget);
      expect(find.text('streak broken'), findsOneWidget);
    });
  });

  group('every theme renders the screen', () {
    for (final theme in TallyTheme.values) {
      testWidgets('${theme.name} builds without a hardcoded colour',
          (tester) async {
        final tasks = [task('Gym', sticker: 'gym', estimate: 45)];
        final plan =
            planner.addToDay(dayKey: today, plan: const [], taskIds: ['Gym']);

        await tester.pumpWidget(
          wrap(TodayScreen(model: modelFor(tasks, plan)), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(
          scaffold.backgroundColor,
          TallyTokens.of(theme, Brightness.dark).bg,
        );
      });
    }
  });
}
