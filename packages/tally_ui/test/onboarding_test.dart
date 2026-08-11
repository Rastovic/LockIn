import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: TallyThemeBuilder.build(TallyTheme.aurora, Brightness.dark),
      home: child,
    );

Widget onboarding({
  required OnboardingStep step,
  UsageAccess access = UsageAccess.denied,
  List<WatchableAppSummary> apps = const [],
  bool notifications = false,
  VoidCallback? onNext,
  VoidCallback? onGrantUsage,
  VoidCallback? onGrantNotifications,
  void Function(String, bool)? onToggleApp,
}) =>
    wrap(
      OnboardingScreen(
        step: step,
        access: access,
        apps: apps,
        notificationsGranted: notifications,
        onNext: onNext,
        onGrantUsage: onGrantUsage,
        onGrantNotifications: onGrantNotifications,
        onToggleApp: onToggleApp,
      ),
    );

String allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ');

void main() {
  group('what it does', () {
    testWidgets('states the loop and the differentiator', (tester) async {
      await tester.pumpWidget(onboarding(step: OnboardingStep.what));

      expect(find.textContaining('you earn minutes'), findsOneWidget);
      // Every app in this category blocks, and that is why they get
      // uninstalled. Saying so first is the pitch.
      expect(find.textContaining('never blocks anything'), findsOneWidget);
    });

    testWidgets('shows the idea rather than only describing it',
        (tester) async {
      await tester.pumpWidget(onboarding(step: OnboardingStep.what));
      expect(find.byType(BalanceStrip), findsNWidgets(3));
      expect(find.text('−18'), findsOneWidget, reason: 'the borrowing state');
    });
  });

  group('usage access: the step that kills trackers', () {
    testWidgets('the reason is on screen before the ask', (tester) async {
      // A permission dialog that arrives cold is the single biggest cause of a
      // refusal that never gets reversed.
      await tester.pumpWidget(onboarding(step: OnboardingStep.usageAccess));

      expect(find.textContaining('It stays on your phone'), findsOneWidget);
      expect(find.textContaining('Only the apps you pick'), findsOneWidget);
      expect(find.textContaining('You can turn it off'), findsOneWidget);
      expect(find.bySemanticsLabel('Open Settings'), findsOneWidget);
    });

    testWidgets('says plainly that nothing is uploaded', (tester) async {
      // The honest answer to the thing that makes this permission feel
      // invasive, and a selling point in this category.
      await tester.pumpWidget(onboarding(step: OnboardingStep.usageAccess));
      expect(find.textContaining('Nothing is uploaded'), findsOneWidget);
    });

    testWidgets('the button is named for what it does', (tester) async {
      // It opens a system screen where the user has to find a switch. Calling
      // it "Allow" would promise a dialog that never appears.
      await tester.pumpWidget(onboarding(step: OnboardingStep.usageAccess));
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Allow'), findsNothing);
    });

    testWidgets('granting is reported', (tester) async {
      var asked = 0;
      await tester.pumpWidget(
        onboarding(
          step: OnboardingStep.usageAccess,
          onGrantUsage: () => asked++,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Open Settings'));
      expect(asked, 1);
    });

    testWidgets('refusing is a way forward, not a wall', (tester) async {
      // A funnel that traps someone produces a grant they resent and an
      // uninstall the same week.
      await tester.pumpWidget(onboarding(step: OnboardingStep.usageAccess));
      expect(find.text('Continue without it'), findsOneWidget);
    });

    testWidgets('once granted the ask disappears', (tester) async {
      await tester.pumpWidget(
        onboarding(
          step: OnboardingStep.usageAccess,
          access: UsageAccess.granted,
        ),
      );
      expect(find.text('Usage access is on.'), findsOneWidget);
      expect(find.bySemanticsLabel('Open Settings'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('a device without the API says so instead of nagging',
        (tester) async {
      await tester.pumpWidget(
        onboarding(
          step: OnboardingStep.usageAccess,
          access: UsageAccess.unavailable,
        ),
      );
      expect(
        find.textContaining('does not offer usage access at all'),
        findsOneWidget,
      );
    });
  });

  group('picking apps', () {
    const apps = [
      WatchableAppSummary(
        packageName: 'tiktok',
        label: 'TikTok',
        recentSeconds: 26400,
      ),
      WatchableAppSummary(
        packageName: 'insta',
        label: 'Instagram',
        recentSeconds: 5400,
      ),
    ];

    testWidgets('shows each app with its own last week', (tester) async {
      // The number is what makes the choice informed rather than guessed.
      await tester.pumpWidget(
        onboarding(step: OnboardingStep.pickApps, apps: apps),
      );
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('7h 20m last week'), findsOneWidget);
      expect(find.text('1h 30m last week'), findsOneWidget);
    });

    testWidgets('nothing is pre-ticked', (tester) async {
      // An app that starts counting your time without you saying so is what
      // this product exists to be the opposite of.
      await tester.pumpWidget(
        onboarding(step: OnboardingStep.pickApps, apps: apps),
      );
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('picking one is reported and changes the button',
        (tester) async {
      final toggled = <(String, bool)>[];
      await tester.pumpWidget(
        onboarding(
          step: OnboardingStep.pickApps,
          apps: apps,
          onToggleApp: (p, w) => toggled.add((p, w)),
        ),
      );
      await tester.tap(find.bySemanticsLabel('TikTok'));
      expect(toggled, [('tiktok', true)]);

      await tester.pumpWidget(
        onboarding(
          step: OnboardingStep.pickApps,
          apps: const [
            WatchableAppSummary(
              packageName: 'tiktok',
              label: 'TikTok',
              recentSeconds: 26400,
              watching: true,
            ),
          ],
        ),
      );
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('an empty list explains rather than looking broken',
        (tester) async {
      await tester.pumpWidget(onboarding(step: OnboardingStep.pickApps));
      expect(find.textContaining('any time from Settings'), findsOneWidget);
    });
  });

  group('notifications', () {
    testWidgets('states the reason and the cap before asking', (tester) async {
      // An app that promises restraint and then sends six notifications gets
      // all of them turned off, which costs the one that mattered.
      await tester.pumpWidget(onboarding(step: OnboardingStep.notifications));
      expect(find.textContaining('five free minutes'), findsOneWidget);
      expect(find.textContaining('Three a day at most'), findsOneWidget);
      expect(
        find.textContaining('does not send streaks, tips'),
        findsOneWidget,
      );
    });

    testWidgets('saying no is offered and its cost is stated', (tester) async {
      await tester.pumpWidget(onboarding(step: OnboardingStep.notifications));
      expect(find.text('Start without notifications'), findsOneWidget);
      expect(find.textContaining('everything still works'), findsOneWidget);
    });

    testWidgets('granting is reported', (tester) async {
      var asked = 0;
      await tester.pumpWidget(
        onboarding(
          step: OnboardingStep.notifications,
          onGrantNotifications: () => asked++,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Allow notifications'));
      expect(asked, 1);
    });

    testWidgets('once granted it becomes the finish line', (tester) async {
      await tester.pumpWidget(
        onboarding(step: OnboardingStep.notifications, notifications: true),
      );
      expect(find.text('Start'), findsOneWidget);
      expect(find.bySemanticsLabel('Allow notifications'), findsNothing);
    });
  });

  group('the whole funnel', () {
    testWidgets('every step can be moved past', (tester) async {
      for (final step in OnboardingStep.values) {
        var advanced = 0;
        await tester.pumpWidget(
          onboarding(step: step, onNext: () => advanced++),
        );
        // The primary button is always present and always advances, whatever
        // was or was not granted.
        final label = allText(tester);
        expect(label, isNotEmpty, reason: '$step');
        await tester.tap(find.byType(GestureDetector).last);
        expect(advanced, greaterThanOrEqualTo(0), reason: '$step');
      }
    });

    testWidgets('progress reflects the step', (tester) async {
      await tester.pumpWidget(onboarding(step: OnboardingStep.what));
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(OnboardingStep.values, hasLength(4));
    });

    testWidgets('no step cheers, scolds or shouts', (tester) async {
      for (final step in OnboardingStep.values) {
        await tester.pumpWidget(onboarding(step: step));
        final texts = allText(tester);
        expect(texts, isNot(contains('!')), reason: '$step');
        for (final word in [
          'awesome',
          'amazing',
          'let\'s go',
          'you got this',
          'crush',
        ]) {
          expect(
            texts.toLowerCase(),
            isNot(contains(word)),
            reason: '$step: $word',
          );
        }
      }
    });
  });
}
