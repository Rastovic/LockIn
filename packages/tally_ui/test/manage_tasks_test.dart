import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

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

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
      home: child,
    );

Widget manage({
  required List<Task> tasks,
  TaskKind segment = TaskKind.oneoff,
  Map<String, int> streaks = const {},
  Set<String> planned = const {},
  ValueChanged<TaskKind>? onSegment,
  void Function(Task)? onEdit,
  void Function(Task)? onAdd,
  VoidCallback? onCreate,
}) =>
    wrap(
      ManageTasksScreen(
        model: ManageTasksModel(
          tasks: tasks,
          now: now,
          streaks: streaks,
          plannedToday: planned,
        ),
        segment: segment,
        onSegment: onSegment ?? (_) {},
        onEdit: onEdit,
        onAddToToday: onAdd,
        onCreate: onCreate,
      ),
    );

/// Gives the test a phone-shaped viewport.
///
/// The default is landscape 800x600, which is not a shape this app ever runs
/// in and which makes a bottom sheet behave nothing like it does on a device.
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The sheet scrolls, so a control below the fold has to be brought into view
/// before it can be tapped. Real users scroll; the test has to as well.
Future<void> tapScrolled(WidgetTester tester, String label) async {
  final finder = find.bySemanticsLabel(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  group('the four segments', () {
    testWidgets('each shows only its own kind', (tester) async {
      final tasks = [
        task('Piano', kind: TaskKind.habit),
        task('Thesis intro', kind: TaskKind.projectTask),
        task('Clean the flat', kind: TaskKind.dread),
        task('Book the dentist'),
      ];

      await tester.pumpWidget(manage(tasks: tasks, segment: TaskKind.habit));
      expect(find.text('Piano'), findsOneWidget);
      expect(find.text('Book the dentist'), findsNothing);

      await tester.pumpWidget(manage(tasks: tasks, segment: TaskKind.dread));
      expect(find.text('Clean the flat'), findsOneWidget);
      expect(find.text('Piano'), findsNothing);
    });

    testWidgets('the chips carry counts so the whole list is readable',
        (tester) async {
      // Without counts you have to open each segment to learn whether anything
      // is in it, which is four taps to answer one question.
      await tester.pumpWidget(
        manage(
          tasks: [
            task('a', kind: TaskKind.habit),
            task('b', kind: TaskKind.habit),
            task('c', kind: TaskKind.dread),
          ],
          segment: TaskKind.habit,
        ),
      );
      expect(find.text('Daily 2'), findsOneWidget);
      expect(find.text('Avoiding 1'), findsOneWidget);
      expect(find.text('Someday 0'), findsOneWidget);
    });

    testWidgets('switching segment is reported', (tester) async {
      TaskKind? picked;
      await tester.pumpWidget(
        manage(tasks: const [], onSegment: (k) => picked = k),
      );
      await tester.tap(find.bySemanticsLabel('Avoiding'));
      expect(picked, TaskKind.dread);
    });

    testWidgets('archived tasks are hidden but not deleted', (tester) async {
      final archived = Task(
        id: 'old',
        kind: TaskKind.oneoff,
        title: 'old',
        createdAt: DateTime.utc(2026, 1, 1),
        archivedAt: DateTime.utc(2026, 6, 1),
      );
      await tester.pumpWidget(manage(tasks: [archived, task('live')]));
      expect(find.text('old'), findsNothing);
      expect(find.text('live'), findsOneWidget);
      expect(find.text('Someday 1'), findsOneWidget);
    });
  });

  group('each kind shows the one line it earns', () {
    testWidgets('a habit shows its days and streak', (tester) async {
      await tester.pumpWidget(
        manage(
          tasks: [task('Piano', kind: TaskKind.habit, weekdays: {2, 4})],
          segment: TaskKind.habit,
          streaks: {'Piano': 12},
        ),
      );
      expect(find.text('Tue · Thu · streak 12'), findsOneWidget);
    });

    testWidgets('a habit with no days set is every day', (tester) async {
      // An empty selection means every day rather than no days, so there is no
      // state that silently means "never".
      await tester.pumpWidget(
        manage(
          tasks: [task('Water', kind: TaskKind.habit)],
          segment: TaskKind.habit,
        ),
      );
      expect(find.text('every day'), findsOneWidget);
    });

    testWidgets('a dread task counts the days', (tester) async {
      await tester.pumpWidget(
        manage(
          tasks: [
            task(
              'Clean the flat',
              kind: TaskKind.dread,
              created: DateTime.utc(2026, 7, 8),
            ),
          ],
          segment: TaskKind.dread,
        ),
      );
      expect(find.text('avoided 34 days'), findsOneWidget);
    });

    testWidgets('a dread task added today does not say avoided 0 days',
        (tester) async {
      await tester.pumpWidget(
        manage(
          tasks: [task('New', kind: TaskKind.dread, created: now)],
          segment: TaskKind.dread,
        ),
      );
      expect(find.text('added today'), findsOneWidget);
      expect(find.textContaining('avoided'), findsNothing);
    });

    testWidgets('a one-off carries nothing unless it is planned',
        (tester) async {
      await tester.pumpWidget(manage(tasks: [task('Dentist')]));
      expect(find.text('in today'), findsNothing);

      await tester.pumpWidget(
        manage(tasks: [task('Dentist')], planned: {'Dentist'}),
      );
      expect(find.text('in today'), findsOneWidget);
    });
  });

  group('adding to today', () {
    testWidgets('reports the task', (tester) async {
      Task? added;
      await tester.pumpWidget(
        manage(tasks: [task('Dentist')], onAdd: (t) => added = t),
      );
      await tester.tap(find.bySemanticsLabel('Mark Dentist done'));
      expect(added?.id, 'Dentist');
    });

    testWidgets('is not offered for something already in today',
        (tester) async {
      // Otherwise the same task lands twice and the planner has to silently
      // ignore the second one.
      var added = 0;
      await tester.pumpWidget(
        manage(
          tasks: [task('Dentist')],
          planned: {'Dentist'},
          onAdd: (_) => added++,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Mark Dentist done'));
      expect(added, 0);
    });
  });

  group('the empty states explain the kinds', () {
    testWidgets('each segment says what it is for', (tester) async {
      // An empty list is the only place the difference between four kinds can
      // be explained without a tutorial.
      for (final (kind, phrase) in [
        (TaskKind.habit, 'carry a streak'),
        (TaskKind.projectTask, 'no deadlines'),
        (TaskKind.dread, 'counts the days'),
        (TaskKind.oneoff, 'carry nothing'),
      ]) {
        await tester.pumpWidget(manage(tasks: const [], segment: kind));
        expect(find.textContaining(phrase), findsOneWidget, reason: '$kind');
      }
    });

    testWidgets('no empty state cheers or scolds', (tester) async {
      for (final kind in TaskKind.values) {
        await tester.pumpWidget(manage(tasks: const [], segment: kind));
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' ');
        expect(texts, isNot(contains('!')), reason: '$kind');
      }
    });

    testWidgets('the create button names the kind', (tester) async {
      await tester.pumpWidget(manage(tasks: const [], segment: TaskKind.dread));
      expect(
        find.text('Add something you are avoiding'),
        findsOneWidget,
      );
    });
  });

  group('the task sheet', () {
    setUp(() {});
    testWidgets('creates a task of the chosen kind', (tester) async {
      TaskDraft? saved;
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (d) => saved = d))),
      );

      await tester.enterText(find.byType(TextField), 'Clean the flat');
      await tapScrolled(tester, 'Avoiding');
      await tapScrolled(tester, 'Add task');

      expect(saved?.title, 'Clean the flat');
      expect(saved?.kind, TaskKind.dread);
    });

    testWidgets('will not save an empty title', (tester) async {
      var saves = 0;
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (_) => saves++))),
      );
      await tapScrolled(tester, 'Add task');
      expect(saves, 0);
    });

    testWidgets('will not save a title that is only spaces', (tester) async {
      var saves = 0;
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (_) => saves++))),
      );
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tapScrolled(tester, 'Add task');
      expect(saves, 0);
    });

    testWidgets('week dots appear only for a daily task', (tester) async {
      // A dread task has no schedule, and offering an input that does nothing
      // is worse than not offering it.
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (_) {}))),
      );
      expect(find.bySemanticsLabel('Monday'), findsNothing);

      await tapScrolled(tester, 'Daily');
      expect(find.bySemanticsLabel('Monday'), findsOneWidget);
    });

    testWidgets('picks weekdays, a sticker and an estimate', (tester) async {
      TaskDraft? saved;
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (d) => saved = d))),
      );

      await tester.enterText(find.byType(TextField), 'Piano');
      await tapScrolled(tester, 'Daily');
      await tapScrolled(tester, 'Tuesday');
      await tapScrolled(tester, 'Thursday');
      await tapScrolled(tester, '20 minutes');
      await tapScrolled(tester, 'Add task');

      expect(saved?.habitWeekdays, {2, 4});
      expect(saved?.estimateMinutes, 20);
    });

    testWidgets('every estimate offered can actually earn', (tester) async {
      // An option under the five minute floor would produce a task whose own
      // estimate could never earn a minute.
      const settings = LedgerSettings();
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (_) {}))),
      );
      for (final minutes in [5, 10, 15, 20, 30, 45, 60]) {
        expect(
          minutes,
          greaterThanOrEqualTo(settings.minEarnBlockMinutes),
          reason: '$minutes',
        );
        expect(find.bySemanticsLabel('$minutes minutes'), findsOneWidget);
      }
    });

    testWidgets('tapping a chosen estimate again clears it', (tester) async {
      TaskDraft? saved;
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (d) => saved = d))),
      );
      await tester.enterText(find.byType(TextField), 'Something');
      await tester.tap(find.bySemanticsLabel('20 minutes'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('20 minutes'));
      await tester.pump();
      await tapScrolled(tester, 'Add task');
      expect(saved?.estimateMinutes, isNull);
    });

    testWidgets('editing loads what was there and offers delete',
        (tester) async {
      var deleted = 0;
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: TaskSheet(
              existing: task(
                'Piano',
                kind: TaskKind.habit,
                estimate: 20,
                weekdays: {2},
              ),
              onSave: (_) {},
              onDelete: () => deleted++,
            ),
          ),
        ),
      );

      expect(find.text('Edit task'), findsOneWidget);
      expect(find.text('Piano'), findsOneWidget);
      // The label is asserted separately from the tap: a control can be
      // reachable by a screen reader and still be off-screen for a finger.
      expect(find.bySemanticsLabel('Delete task'), findsOneWidget);
      await tester.ensureVisible(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      expect(deleted, 1);
    });

    testWidgets('creating does not offer delete', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(Scaffold(body: TaskSheet(onSave: (_) {}))),
      );
      expect(find.bySemanticsLabel('Delete task'), findsNothing);
      expect(find.text('New task'), findsOneWidget);
    });
  });
}
