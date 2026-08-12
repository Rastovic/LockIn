import 'package:flutter/material.dart';

import 'state_colors.dart';

/// Tally's two themes.
///
/// Each is authored in **both** light and dark, so the system switch never
/// fights the user's choice. Four token sets in total.
///
/// **Two, not three.** The plan originally specified a third, Graphite, as a
/// cool light theme. Seen side by side it was Aurora with a different neutral,
/// which is not a choice worth offering: a theme picker earns its place by
/// making the app feel different, not by adding a row. Cutting it also removes
/// a third of the golden set and a third of the contrast surface.
enum TallyTheme {
  /// Default. Near-black ground, mint solvent. The identity.
  aurora,

  /// Warm and pink. **The theme the store listing is shot in**, because dark
  /// screenshots disappear against a light store page.
  blush;

  String get label => switch (this) {
        TallyTheme.aurora => 'Aurora',
        TallyTheme.blush => 'Blush',
      };
}

/// Every colour and measurement a screen may use.
///
/// **No component may hardcode a colour.** Everything reads from here, which is
/// what makes adding a fourth theme an afternoon rather than a redesign, and
/// `theme_test.dart` asserts it over the whole widget tree.
@immutable
final class TallyTokens extends ThemeExtension<TallyTokens> {
  const TallyTokens({
    required this.theme,
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.states,
  });

  final TallyTheme theme;
  final Brightness brightness;

  /// The ground. Near-black in Aurora rather than the shared `#0E1116`, because
  /// the state glow needs somewhere darker to sit against.
  final Color bg;

  /// Glass cards. Deliberately a translucent overlay rather than an opaque
  /// colour, so a card over the glow tints with it.
  final Color surface;

  /// Nested chips and controls.
  final Color surfaceStrong;

  final Color ink;
  final Color inkMuted;
  final Color inkFaint;

  final StateColors states;

  Color colorFor(BalanceState state) => states.of(state);

  /// The colour for the blurred field behind the balance, which is not always
  /// the colour of the number in front of it. See [StateColors.borrowingGlow].
  Color glowFor(BalanceState state) => states.glowFor(state);

  @override
  TallyTokens copyWith({
    TallyTheme? theme,
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? surfaceStrong,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    StateColors? states,
  }) =>
      TallyTokens(
        theme: theme ?? this.theme,
        brightness: brightness ?? this.brightness,
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceStrong: surfaceStrong ?? this.surfaceStrong,
        ink: ink ?? this.ink,
        inkMuted: inkMuted ?? this.inkMuted,
        inkFaint: inkFaint ?? this.inkFaint,
        states: states ?? this.states,
      );

  /// Token sets swap wholesale rather than blending: a half-interpolated
  /// palette mid-transition is never a state the design intends.
  @override
  TallyTokens lerp(ThemeExtension<TallyTokens>? other, double t) {
    if (other is! TallyTokens) return this;
    return t < 0.5 ? this : other;
  }

  /// The four authored sets: two themes, each in light and dark.
  ///
  /// Every state colour here has been measured against the ground it sits on.
  /// The light themes darken their state colours rather than reusing the dark
  /// theme's, because mint that reads on near-black is illegible on white.
  static TallyTokens of(TallyTheme theme, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (theme) {
      TallyTheme.aurora => dark ? _auroraDark : _auroraLight,
      TallyTheme.blush => dark ? _blushDark : _blushLight,
    };
  }

  static const _auroraDark = TallyTokens(
    theme: TallyTheme.aurora,
    brightness: Brightness.dark,
    bg: Color(0xFF0A0D13),
    surface: Color(0x0EFFFFFF),
    surfaceStrong: Color(0x17FFFFFF),
    ink: Color(0xFFF2F6FA),
    inkMuted: Color(0xFF9AA6B5),
    inkFaint: Color(0xFF6B7788),
    states: StateColors(
      solvent: Color(0xFF4FE3A1),
      low: Color(0xFFFFC24B),
      borrowing: Color(0xFFFF5C7A),
      savings: Color(0xFF9E9BFF),
    ),
  );

  static const _auroraLight = TallyTokens(
    theme: TallyTheme.aurora,
    brightness: Brightness.light,
    bg: Color(0xFFF3F6F9),
    surface: Color(0x0F0A0D13),
    surfaceStrong: Color(0x1A0A0D13),
    ink: Color(0xFF0A0D13),
    inkMuted: Color(0xFF515C6B),
    inkFaint: Color(0xFF7C8797),
    states: StateColors(
      solvent: Color(0xFF0B8F5F),
      low: Color(0xFF8A5A05),
      borrowing: Color(0xFFC3213F),
      savings: Color(0xFF534BD1),
    ),
  );

  static const _blushDark = TallyTokens(
    theme: TallyTheme.blush,
    brightness: Brightness.dark,
    bg: Color(0xFF1A1016),
    surface: Color(0x14FFFFFF),
    surfaceStrong: Color(0x1FFFFFFF),
    ink: Color(0xFFFBEEF3),
    inkMuted: Color(0xFFC2A3B0),
    inkFaint: Color(0xFF8E7480),
    // Borrowing is a clear red, not another pink. Blush dark first shipped
    // #FF6B85, which sat 104 perceptual units from the pink solvent - close
    // enough to be confused at a glance, which is the exact failure the
    // state-colour rule exists to prevent. #FF5252 sits at 190.
    states: StateColors(
      solvent: Color(0xFFF48FB8),
      low: Color(0xFFF0B44E),
      borrowing: Color(0xFFFF5252),
      savings: Color(0xFFBFA4F5),
    ),
  );

  static const _blushLight = TallyTokens(
    theme: TallyTheme.blush,
    brightness: Brightness.light,
    bg: Color(0xFFFFF6F8),
    surface: Color(0x0F8B3C5A),
    surfaceStrong: Color(0x1A8B3C5A),
    ink: Color(0xFF2A1922),
    inkMuted: Color(0xFF6B4E5A),
    inkFaint: Color(0xFF9C8590),
    // Same correction as Blush dark, and it matters more here: this is the
    // theme the store listing is shot in. The first pass used #A81B3B, a
    // crimson only 99 units from the rose solvent. #B81E1E is a true red at
    // 133, still warm enough to belong to the palette.
    states: StateColors(
      solvent: Color(0xFFB03A6D),
      low: Color(0xFF8A5605),
      borrowing: Color(0xFFB81E1E),
      savings: Color(0xFF6741C4),
      // Blurred behind the balance, #B81E1E composites to #DC8A8B - brick,
      // and muddy against a pink theme. This tint composites to #F8ABBC and
      // sits 68 units from the solvent glow where the dark red sat 64, so the
      // pinker choice also tells the two states apart slightly better.
      borrowingGlow: Color(0xFFF0607F),
    ),
  );
}
