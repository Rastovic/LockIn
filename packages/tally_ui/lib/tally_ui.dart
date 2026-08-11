/// Tally's screens and its visual identity.
///
/// The identity is **state as data**: a blurred field behind the balance takes
/// the hue of what the balance is doing, so the screen reads before a single
/// word does. Three themes, each authored light and dark, and no component may
/// hardcode a colour - `theme_test.dart` asserts that over the widget tree.
library;

export 'src/screens/focus_screen.dart';
export 'src/screens/today_screen.dart';
export 'src/theme/state_colors.dart';
export 'src/theme/tally_theme.dart';
export 'src/theme/tally_theme_data.dart';
export 'src/widgets/balance_strip.dart';
export 'src/widgets/sticker_chip.dart';
export 'src/widgets/task_row.dart';
