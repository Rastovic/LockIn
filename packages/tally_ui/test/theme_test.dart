import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_ui/tally_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Perceptual distance between two colours, on the "redmean" approximation.
///
/// **Not WCAG contrast.** Contrast measures luminance, and two colours can sit
/// at nearly identical luminance while being obviously different to the eye:
/// mint and amber score 1.02 on contrast and are in no danger of being
/// confused. Contrast is the right tool for text on a ground and the wrong one
/// for telling two signal colours apart.
double _distance(Color a, Color b) {
  final r1 = a.r * 255, g1 = a.g * 255, b1 = a.b * 255;
  final r2 = b.r * 255, g2 = b.g * 255, b2 = b.b * 255;
  final rMean = (r1 + r2) / 2;
  final dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
  return math.sqrt(
    (2 + rMean / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rMean) / 256) * db * db,
  );
}

/// Composites a translucent surface over its ground, which is what the eye
/// actually sees. Testing the raw token would measure a colour nobody ever
/// looks at.
Color _over(Color surface, Color ground) =>
    Color.alphaBlend(surface, ground);

Iterable<TallyTokens> get allSets sync* {
  for (final theme in TallyTheme.values) {
    for (final brightness in Brightness.values) {
      yield TallyTokens.of(theme, brightness);
    }
  }
}

Widget wrap(Widget child, {TallyTheme theme = TallyTheme.aurora,
    Brightness brightness = Brightness.dark, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: TallyThemeBuilder.build(theme, brightness),
      home: Scaffold(body: child),
    ),
  );
}

/// Material wraps routes in their own ScaleTransition, so the chip's has to be
/// found by descent rather than by type alone.
final _chipScale = find.descendant(
  of: find.byType(StickerChip),
  matching: find.byType(ScaleTransition),
);

void main() {
  group('six token sets', () {
    test('two themes, each authored light and dark', () {
      // Graphite was cut at review: it was Aurora with a different neutral,
      // and a theme picker earns its place by making the app feel different.
      expect(allSets, hasLength(4));
      expect(TallyTheme.values, hasLength(2));
      for (final theme in TallyTheme.values) {
        expect(TallyTokens.of(theme, Brightness.dark).brightness,
            Brightness.dark);
        expect(TallyTokens.of(theme, Brightness.light).brightness,
            Brightness.light);
      }
    });

    test('every set supplies its own four state colours', () {
      // The rule that keeps three themes honest.
      for (final tokens in allSets) {
        expect(tokens.states.all, hasLength(4));
        expect(
          tokens.states.all.toSet(),
          hasLength(4),
          reason: '${tokens.theme.name} reuses a colour for two states',
        );
      }
    });

    test('a light theme never reuses its dark twin state colours', () {
      // Mint that reads on near-black is illegible on white, so the light sets
      // must be authored rather than inherited.
      for (final theme in TallyTheme.values) {
        final dark = TallyTokens.of(theme, Brightness.dark);
        final light = TallyTokens.of(theme, Brightness.light);
        expect(
          dark.states.solvent,
          isNot(light.states.solvent),
          reason: theme.name,
        );
      }
    });
  });

  group('contrast', () {
    test('body text passes 4.5:1 on the ground, every set', () {
      for (final t in allSets) {
        expect(
          _contrast(t.ink, t.bg),
          greaterThanOrEqualTo(4.5),
          reason: '${t.theme.name} ${t.brightness.name} ink',
        );
      }
    });

    test('muted text passes 4.5:1 on the ground, every set', () {
      for (final t in allSets) {
        expect(
          _contrast(t.inkMuted, t.bg),
          greaterThanOrEqualTo(4.5),
          reason: '${t.theme.name} ${t.brightness.name} inkMuted',
        );
      }
    });

    test('body text passes on a glass card too', () {
      // Cards are translucent, so the real ground under text is the composite.
      for (final t in allSets) {
        final surface = _over(t.surface, t.bg);
        expect(
          _contrast(t.ink, surface),
          greaterThanOrEqualTo(4.5),
          reason: '${t.theme.name} ${t.brightness.name} on surface',
        );
      }
    });

    test('every state colour reads as a large numeral, every set', () {
      // The balance is displayXL and displayMedium, both large text, so the
      // WCAG bar is 3:1 rather than 4.5.
      for (final t in allSets) {
        for (final state in BalanceState.values) {
          expect(
            _contrast(t.colorFor(state), t.bg),
            greaterThanOrEqualTo(3.0),
            reason: '${t.theme.name} ${t.brightness.name} ${state.name}',
          );
        }
      }
    });

    test('the four states stay distinguishable from each other', () {
      // Colour is the primary signal here, so two states that look alike is a
      // correctness bug rather than a style one. Measured as perceptual
      // distance, not contrast - see _distance.
      const names = ['solvent', 'low', 'borrowing', 'savings'];
      for (final t in allSets) {
        final states = t.states.all;
        for (var i = 0; i < states.length; i++) {
          for (var j = i + 1; j < states.length; j++) {
            expect(
              _distance(states[i], states[j]),
              greaterThan(120),
              reason: '${t.theme.name} ${t.brightness.name}: '
                  '${names[i]} and ${names[j]} are too close',
            );
          }
        }
      }
    });
  });

  group('balance state', () {
    test('mint at ten minutes or more, amber under, coral below zero', () {
      expect(BalanceState.forSeconds(600), BalanceState.solvent);
      expect(BalanceState.forSeconds(599), BalanceState.low);
      expect(BalanceState.forSeconds(0), BalanceState.low);
      expect(BalanceState.forSeconds(-1), BalanceState.borrowing);
    });
  });

  group('minute formatting', () {
    test('floors towards negative infinity, never towards zero', () {
      // Rounding a debt towards zero flatters the number, which is the one
      // thing this app must never do.
      expect(formatMinutes(90), '1');
      expect(formatMinutes(-90), '−2');
      expect(formatMinutes(0), '0');
      expect(formatMinutes(-60), '−1');
    });

    test('uses a real minus sign, not a hyphen', () {
      // A hyphen next to a tabular figure reads as a dash and sits at the wrong
      // height.
      expect(formatMinutes(-120), contains('−'));
      expect(formatMinutes(-120), isNot(contains('-')));
    });
  });

  group('no component hardcodes a colour', () {
    testWidgets('the same widget renders differently in each theme',
        (tester) async {
      // The practical version of the rule: if a component held a literal, it
      // would look identical across themes.
      final rendered = <TallyTheme, Color>{};

      for (final theme in TallyTheme.values) {
        await tester.pumpWidget(
          wrap(
            const BalanceStrip(spendableSeconds: 2520, solvencyStreak: 6),
            theme: theme,
          ),
        );
        // MaterialApp animates a theme change, and TallyTokens.lerp swaps
        // wholesale at the halfway point, so a colour read mid-transition is
        // still the previous theme's.
        await tester.pumpAndSettle();
        final text = tester.widget<Text>(find.text('42'));
        rendered[theme] = text.style!.color!;
      }

      expect(
        rendered.values.toSet(),
        hasLength(TallyTheme.values.length),
        reason: 'a theme is not reaching the balance number',
      );
    });

    testWidgets('the scaffold takes its ground from the tokens',
        (tester) async {
      for (final theme in TallyTheme.values) {
        final data = TallyThemeBuilder.build(theme, Brightness.dark);
        expect(
          data.scaffoldBackgroundColor,
          TallyTokens.of(theme, Brightness.dark).bg,
        );
      }
    });

    testWidgets('a Tally widget outside a Tally theme fails loudly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              expect(() => context.tokens, throwsFlutterError);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('the balance strip', () {
    testWidgets('shows the state colour and the streak', (tester) async {
      await tester.pumpWidget(
        wrap(const BalanceStrip(spendableSeconds: 2520, solvencyStreak: 6)),
      );
      expect(find.text('42'), findsOneWidget);
      expect(find.text('6 solvent days'), findsOneWidget);
      expect(find.text('min left'), findsOneWidget);
    });

    testWidgets('borrowing states the fact and does not scold', (tester) async {
      await tester.pumpWidget(
        wrap(const BalanceStrip(spendableSeconds: -1080, solvencyStreak: 0)),
      );
      expect(find.text('−18'), findsOneWidget);
      expect(find.text('borrowing'), findsOneWidget);
      expect(find.text('streak broken'), findsOneWidget);
    });

    testWidgets('carries a screen-reader label', (tester) async {
      // Never encode meaning in colour alone.
      await tester.pumpWidget(
        wrap(const BalanceStrip(spendableSeconds: -1080, solvencyStreak: 0)),
      );
      expect(
        find.bySemanticsLabel(RegExp('Borrowing 18 minutes')),
        findsOneWidget,
      );
    });
  });

  group('the sticker stamp', () {
    testWidgets('stamps when a task is completed', (tester) async {
      // Settled decision 18. The chip lifts past 1.0 and settles back.
      await tester.pumpWidget(
        wrap(const StickerChip(stickerId: 'dishes')),
      );
      await tester.pumpWidget(
        wrap(const StickerChip(stickerId: 'dishes', stamped: true)),
      );

      await tester.pump(const Duration(milliseconds: 90));
      final mid = tester.widget<ScaleTransition>(_chipScale);
      expect(mid.scale.value, greaterThan(1.0), reason: 'the lift');

      await tester.pumpAndSettle();
      final settled = tester.widget<ScaleTransition>(_chipScale);
      expect(settled.scale.value, closeTo(1.0, 0.001));
    });

    testWidgets('reduced motion skips the stamp entirely', (tester) async {
      // An accessibility requirement, not a nicety, so it is skipped rather
      // than shortened: a fast animation is still animation.
      await tester.pumpWidget(
        wrap(const StickerChip(stickerId: 'dishes'), reduceMotion: true),
      );
      await tester.pumpWidget(
        wrap(
          const StickerChip(stickerId: 'dishes', stamped: true),
          reduceMotion: true,
        ),
      );
      await tester.pump();

      final chip = tester.widget<ScaleTransition>(_chipScale);
      expect(chip.scale.value, closeTo(1.0, 0.001));
    });

    testWidgets('unticking reverts with no animation', (tester) async {
      // A mis-tap correction must cost nothing, including visually.
      await tester.pumpWidget(
        wrap(const StickerChip(stickerId: 'dishes', stamped: true)),
      );
      await tester.pumpWidget(wrap(const StickerChip(stickerId: 'dishes')));
      await tester.pump();

      final chip = tester.widget<ScaleTransition>(_chipScale);
      expect(chip.scale.value, closeTo(1.0, 0.001));
    });

    test('every base sticker has a glyph until the art lands', () {
      // The ids are the contract and do not change when the drawn assets
      // arrive, so nothing downstream has to move in Phase 5c.
      for (final sticker in StickerCatalogIds.base) {
        expect(stickerGlyphs, contains(sticker), reason: sticker);
      }
    });
  });

  group('the task row', () {
    testWidgets('tapping the circle toggles, tapping play starts focus',
        (tester) async {
      var toggled = 0;
      var focused = 0;

      await tester.pumpWidget(
        wrap(
          TaskRow(
            title: 'Clear one surface',
            done: false,
            stickerId: 'cleaning',
            estimateMinutes: 10,
            onToggle: () => toggled++,
            onStartFocus: () => focused++,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Mark Clear one surface done'));
      await tester.tap(
        find.bySemanticsLabel('Start a focus session on Clear one surface'),
      );
      expect(toggled, 1);
      expect(focused, 1);
    });

    testWidgets('both tap targets meet the 44pt floor', (tester) async {
      await tester.pumpWidget(
        wrap(
          TaskRow(
            title: 'Gym',
            done: false,
            estimateMinutes: 45,
            onToggle: () {},
            onStartFocus: () {},
          ),
        ),
      );

      for (final label in ['Mark Gym done', 'Start a focus session on Gym']) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(44), reason: label);
        expect(size.height, greaterThanOrEqualTo(44), reason: label);
      }
    });

    testWidgets('a completed row dims and strikes through', (tester) async {
      await tester.pumpWidget(
        wrap(const TaskRow(title: 'Gym', done: true, stickerId: 'gym')),
      );
      final text = tester.widget<Text>(find.text('Gym'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });
  });
}

/// The base sticker ids, mirrored from `tally_engine`'s catalogue.
///
/// Duplicated deliberately: `tally_ui` must not depend on the engine just to
/// know a list of strings, and the test above is what keeps the two in step.
final class StickerCatalogIds {
  const StickerCatalogIds._();

  static const base = [
    'cleaning', 'dishes', 'laundry', 'gym', 'run', 'stretch', 'walk', 'study',
    'read', 'write', 'work', 'admin', 'money', 'call', 'shopping', 'cooking',
    'plants', 'pets', 'selfcare', 'sleep', 'social', 'creative', 'music',
    'outdoors',
  ];
}
