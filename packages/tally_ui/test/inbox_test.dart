import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

Task captured(String title) => Task(
      id: title,
      kind: TaskKind.oneoff,
      title: title,
      createdAt: DateTime.utc(2026, 8, 14),
      needsSorting: true,
    );

Task sorted(String title) => Task(
      id: title,
      kind: TaskKind.habit,
      title: title,
      createdAt: DateTime.utc(2026, 8, 14),
    );

Widget screen(List<Task> tasks, {bool inbox = false}) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.blush, Brightness.light),
      home: ManageTasksScreen(
        model: ManageTasksModel(
          tasks: tasks,
          now: DateTime.utc(2026, 8, 14, 9),
        ),
        segment: null,
        inbox: inbox,
        onSegment: (_) {},
        onInbox: () {},
      ),
    );

void main() {
  testWidgets('the inbox chip appears only when something is waiting',
      (tester) async {
    // A permanently visible empty inbox is a chore on display.
    await tester.pumpWidget(screen([sorted('Piano')]));
    expect(find.textContaining('Inbox'), findsNothing);

    await tester.pumpWidget(screen([sorted('Piano'), captured('Dentist')]));
    expect(find.text('Inbox 1'), findsOneWidget);
  });

  testWidgets('it shows only what has not been sorted', (tester) async {
    await tester.pumpWidget(
      screen([sorted('Piano'), captured('Dentist')], inbox: true),
    );
    expect(find.text('Dentist'), findsOneWidget);
    expect(find.text('Piano'), findsNothing);
  });

  testWidgets('an empty inbox reads as finished, not broken', (tester) async {
    await tester.pumpWidget(screen([sorted('Piano')], inbox: true));
    expect(find.text('Nothing to sort'), findsOneWidget);
    // The good state, so the copy must not sound like something is missing.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ')
        .toLowerCase();
    expect(texts, isNot(contains('!')));
    for (final word in ['great', 'well done', 'empty!', 'nothing here']) {
      expect(texts, isNot(contains(word)), reason: word);
    }
  });

  testWidgets('a captured task still appears in All', (tester) async {
    // It is a real task from the moment it is captured. Hiding it until it is
    // sorted would make the inbox a holding pen, which is where captured
    // things go to die.
    await tester.pumpWidget(screen([captured('Dentist')]));
    expect(find.text('Dentist'), findsOneWidget);
  });
}
