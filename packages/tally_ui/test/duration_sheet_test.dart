import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_ui/tally_ui.dart';

/// Choosing how long the block is.
///
/// Before this sheet existed a block simply started, at the task's estimate or
/// at twenty-five minutes. That made the length a property of the task rather
/// than a decision, and the decision is the point: how long is worth giving
/// right now is a different answer every time it is asked.
Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('offers presets and starts the one that was picked',
      (tester) async {
    int? started;
    await tester.pumpWidget(
      wrap(DurationSheet(onStart: (minutes) => started = minutes)),
    );

    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);

    await tester.tap(find.text('45 min'));
    await tester.pump();
    await tester.tap(find.text('Start 45 min'));

    expect(started, 45);
  });

  testWidgets("the task's estimate is what starts if nothing is touched",
      (tester) async {
    // Someone who wrote "45 min" on the task already answered this once, so
    // starting it stays two taps.
    int? started;
    await tester.pumpWidget(
      wrap(
        DurationSheet(
          suggestedMinutes: 45,
          taskTitle: 'Write the intro',
          onStart: (minutes) => started = minutes,
        ),
      ),
    );

    expect(find.text('Write the intro'), findsOneWidget);
    await tester.tap(find.text('Start 45 min'));
    expect(started, 45);
  });

  testWidgets('an odd estimate is offered alongside the presets',
      (tester) async {
    // 40 is not a preset. It still has to be selectable and startable, or the
    // estimate has been quietly overridden by the picker.
    int? started;
    await tester.pumpWidget(
      wrap(
        DurationSheet(
          suggestedMinutes: 40,
          onStart: (minutes) => started = minutes,
        ),
      ),
    );

    expect(find.text('40 min'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget, reason: 'presets still there');
    await tester.tap(find.text('Start 40 min'));
    expect(started, 40);
  });

  testWidgets('five at a time, and it cannot go to zero', (tester) async {
    await tester.pumpWidget(wrap(DurationSheet(onStart: (_) {})));

    await tester.tap(find.bySemanticsLabel('Five minutes more'));
    await tester.pump();
    expect(find.text('Start 30 min'), findsOneWidget);

    for (var i = 0; i < 10; i++) {
      final less = find.bySemanticsLabel('Five minutes less');
      if (less.evaluate().isEmpty) break;
      await tester.tap(less);
      await tester.pump();
    }
    // Five is the floor: a block shorter than the earning minimum earns
    // nothing, and a zero minute timer is not a thing anyone meant to start.
    expect(find.text('Start 5 min'), findsOneWidget);
  });

  testWidgets('past an hour it reads in hours', (tester) async {
    await tester.pumpWidget(
      wrap(DurationSheet(suggestedMinutes: 90, onStart: (_) {})),
    );
    expect(find.text('Start 1h 30m'), findsOneWidget);
  });
}
