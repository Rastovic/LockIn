import 'package:flutter/material.dart';

import 'tally_theme.dart';

/// Builds a [ThemeData] for one Tally theme and brightness.
///
/// The display face is `ui-rounded` where the platform has it. Mono was what
/// made the first draft look like a banking app, so there is none anywhere.
final class TallyThemeBuilder {
  const TallyThemeBuilder._();

  /// The rounded display stack.
  ///
  /// `.SF Pro Rounded` on Apple platforms; Android falls back through the
  /// system stack to Roboto, which is already fairly round. **No custom font
  /// files**, which keeps the bundle small and the licensing simple.
  static const displayFamilies = ['.SF Pro Rounded', 'SF Pro Rounded'];

  static ThemeData build(TallyTheme theme, Brightness brightness) {
    final tokens = TallyTokens.of(theme, brightness);

    // Numbers are the identity of this app, so anything that counts gets
    // tabular figures: a live countdown in proportional figures shifts the
    // layout every time a digit changes width.
    const tabular = [FontFeature.tabularFigures()];

    TextStyle display(double size, FontWeight weight) => TextStyle(
          fontFamilyFallback: displayFamilies,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: size * -0.03,
          height: 1.05,
          color: tokens.ink,
          fontFeatures: tabular,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.bg,
      canvasColor: tokens.bg,
      extensions: [tokens],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tokens.states.solvent,
        onPrimary: tokens.bg,
        secondary: tokens.states.savings,
        onSecondary: tokens.bg,
        error: tokens.states.borrowing,
        onError: tokens.bg,
        surface: tokens.bg,
        onSurface: tokens.ink,
      ),
      textTheme: TextTheme(
        // The hero number. Sized to survive Dynamic Type at 200%.
        displayLarge: display(72, FontWeight.w800),
        // The balance strip, kept at 22 after review: the state glow carries
        // the reading, and the live countdown adds motion a static mock cannot.
        displayMedium: display(22, FontWeight.w800),
        headlineMedium: display(30, FontWeight.w700),
        titleLarge: TextStyle(
          fontFamilyFallback: displayFamilies,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: tokens.ink,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tokens.ink,
          letterSpacing: -0.1,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: tokens.inkMuted,
          height: 1.45,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.inkFaint,
          fontFeatures: tabular,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: tokens.inkFaint,
        ),
      ),
      // No hairline rules anywhere: depth comes from the glass surfaces and the
      // glow, never from a divider.
      dividerTheme: const DividerThemeData(
        color: Color(0x00000000),
        thickness: 0,
        space: 0,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// The tokens for this subtree.
  ///
  /// Throws rather than returning null: a Tally widget outside a Tally theme is
  /// a wiring bug, and failing in a widget test beats falling back to Material
  /// defaults in a release build.
  static TallyTokens tokensOf(BuildContext context) {
    final tokens = Theme.of(context).extension<TallyTokens>();
    if (tokens == null) {
      throw FlutterError(
        'No TallyTokens found. Wrap this subtree in a theme from '
        'TallyThemeBuilder.build().',
      );
    }
    return tokens;
  }
}

extension TallyThemeContext on BuildContext {
  TallyTokens get tokens => TallyThemeBuilder.tokensOf(this);
}
