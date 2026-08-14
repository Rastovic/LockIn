import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
      home: child,
    );

Project project(String id, String name) =>
    Project(id: id, name: name, createdAt: DateTime.utc(2026, 8, 1));

Task task(String title, {String? projectId, int? estimate}) => Task(
      id: title,
      kind: TaskKind.projectTask,
      title: title,
      createdAt: DateTime.utc(2026, 8, 1),
      projectId: projectId,
      estimateMinutes: estimate,
    );

Widget screen(List<Project> projects, List<Task> tasks) => wrap(
      ManageTasksScreen(
        model: ManageTasksModel(
          tasks: tasks,
          projects: projects,
          now: DateTime.utc(2026, 8, 14, 9),
        ),
        segment: TaskKind.projectTask,
        onSegment: (_) {},
        onAddToProject: (_) {},
      ),
    );

void main() {
  group('projects hold tasks', () {
    testWidgets('a project lists its own tasks and nobody else\'s',
        (tester) async {
      await tester.pumpWidget(
        screen(
          [project('p1', 'Dissertation'), project('p2', 'Flat')],
          [
            task('Read the Barron paper', projectId: 'p1'),
            task('Bleed the radiators', projectId: 'p2'),
          ],
        ),
      );

      expect(find.text('Dissertation'), findsOneWidget);
      // Closed by default: the point of a project is that its contents are
      // folded away until asked for.
      expect(find.text('Read the Barron paper'), findsNothing);

      await tester.tap(find.text('Dissertation'));
      await tester.pumpAndSettle();

      expect(find.text('Read the Barron paper'), findsOneWidget);
      expect(find.text('Bleed the radiators'), findsNothing);
    });

    testWidgets('the project carries no time of its own, only its tasks\'',
        (tester) async {
      await tester.pumpWidget(
        screen(
          [project('p1', 'Dissertation')],
          [
            task('Read', projectId: 'p1', estimate: 45),
            task('Outline', projectId: 'p1', estimate: 30),
            task('Unestimated', projectId: 'p1'),
          ],
        ),
      );
      // Derived from the tasks and labelled as a sum. A project with its own
      // stored estimate would be a second number that disagrees with its parts
      // the first time a task changes.
      expect(find.text('3 tasks · 1h 15m planned'), findsOneWidget);
    });

    testWidgets('an empty project says so rather than looking broken',
        (tester) async {
      await tester.pumpWidget(screen([project('p1', 'Dissertation')], []));
      expect(find.text('empty'), findsOneWidget);

      await tester.tap(find.text('Dissertation'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing in here yet.'), findsOneWidget);
    });

    testWidgets('a task with no project is still shown', (tester) async {
      // Including anything left behind when a project was deleted. An unfiled
      // task is still work, and silently hiding it loses it.
      await tester.pumpWidget(
        screen([project('p1', 'Dissertation')], [task('Orphan')]),
      );
      expect(find.text('NOT IN A PROJECT  1'), findsOneWidget);
      expect(find.text('Orphan'), findsOneWidget);
    });
  });

  group('quick tasks', () {
    testWidgets('are their own segment, with no timer offered',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: TaskSheet(
              initialKind: TaskKind.quick,
              onSave: (_) {},
            ),
          ),
        ),
      );
      // Two seconds is not something to put an estimate on, and every option
      // the wheel can offer is longer than the task.
      expect(find.byType(ListWheelScrollView), findsNothing);
      expect(find.text('HOW LONG'), findsNothing);
    });

    testWidgets('carry no streak, unlike a habit', (tester) async {
      await tester.pumpWidget(
        wrap(
          ManageTasksScreen(
            model: ManageTasksModel(
              tasks: [
                Task(
                  id: 'q',
                  kind: TaskKind.quick,
                  title: 'Take supplements',
                  createdAt: DateTime.utc(2026, 8, 1),
                ),
              ],
              now: DateTime.utc(2026, 8, 14, 9),
              streaks: const {'q': 9},
            ),
            segment: TaskKind.quick,
            onSegment: (_) {},
          ),
        ),
      );
      expect(find.text('Take supplements'), findsOneWidget);
      // A streak on a two second job turns it into something you can fail at.
      expect(find.textContaining('streak'), findsNothing);
    });
  });
}
