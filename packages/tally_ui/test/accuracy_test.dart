import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_ui/tally_ui.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.blush, Brightness.light),
      home: child,
    );

AccuracyDay day(List<AccuracyApp> apps) =>
    AccuracyDay(dayKey: '2026-08-14', label: 'Today', apps: apps);

/// The comparison the whole app rests on.
///
/// Every other number is arithmetic on top of one measurement. If that
/// measurement is wrong, everything is confidently wrong together and nothing
/// inside the app would reveal it.
void main() {
  testWidgets('shows what lockIn counted, per app', (tester) async {
    await tester.pumpWidget(
      wrap(
        AccuracyScreen(
          days: [
            day(const [
              AccuracyApp(
                packageName: 'com.tiktok',
                label: 'TikTok',
                seconds: 3990,
              ),
            ]),
          ],
        ),
      ),
    );
    expect(find.text('TikTok'), findsOneWidget);
    // Floored, like every other minute in the app. 66m30s is 66.
    expect(find.text('66m'), findsOneWidget);
  });

  testWidgets('a close reading is called close, not wrong', (tester) async {
    // Two minutes is the honest resolution of the comparison rather than
    // slack: the two count session edges differently and both round.
    await tester.pumpWidget(
      wrap(
        AccuracyScreen(
          days: [
            day(const [
              AccuracyApp(
                packageName: 'com.tiktok',
                label: 'TikTok',
                seconds: 3990,
                reportedMinutes: 65,
              ),
            ]),
          ],
        ),
      ),
    );
    expect(find.textContaining('within rounding'), findsOneWidget);
  });

  testWidgets('a real disagreement says which way it went', (tester) async {
    // Direction matters: counting more than the phone is over-charging the
    // user, counting less is letting spend go unrecorded. They are different
    // bugs and the sentence has to name which one.
    await tester.pumpWidget(
      wrap(
        AccuracyScreen(
          days: [
            day(const [
              AccuracyApp(
                packageName: 'com.tiktok',
                label: 'TikTok',
                seconds: 3600,
                reportedMinutes: 42,
              ),
            ]),
          ],
        ),
      ),
    );
    expect(
      find.text('lockIn counted 18 minutes more than your phone did.'),
      findsOneWidget,
    );
  });

  testWidgets('typing a reading reports it', (tester) async {
    String? gotDay;
    String? gotPackage;
    int? gotMinutes;

    await tester.pumpWidget(
      wrap(
        AccuracyScreen(
          days: [
            day(const [
              AccuracyApp(
                packageName: 'com.tiktok',
                label: 'TikTok',
                seconds: 3600,
              ),
            ]),
          ],
          onReport: (d, p, m) {
            gotDay = d;
            gotPackage = p;
            gotMinutes = m;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '58');
    expect(gotDay, '2026-08-14');
    expect(gotPackage, 'com.tiktok');
    expect(gotMinutes, 58);

    // Clearing it removes the reading rather than recording a zero, which
    // would show as a 60 minute disagreement.
    await tester.enterText(find.byType(TextField), '');
    expect(gotMinutes, isNull);
  });

  testWidgets('nothing counted yet says so plainly', (tester) async {
    await tester.pumpWidget(wrap(AccuracyScreen(days: [day(const [])])));
    expect(find.textContaining('Nothing counted yet'), findsOneWidget);
  });

  testWidgets('says where to find the phone\'s own number', (tester) async {
    // A comparison screen that assumes you know where Digital Wellbeing lives
    // is a comparison that does not get done.
    await tester.pumpWidget(wrap(AccuracyScreen(days: [day(const [])])));
    expect(find.textContaining('Digital Wellbeing'), findsWidgets);
  });
}
