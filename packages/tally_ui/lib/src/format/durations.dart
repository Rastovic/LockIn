/// Every place minutes are shown to the user.
///
/// Centralised because it was not, and the same day showed as 66 minutes on the
/// Statement and 67 on Insights: one screen floored the seconds, the other
/// rounded them. Both were defensible and having both was not. A ledger that
/// disagrees with itself by a minute is a ledger the user is right to stop
/// believing, and the first thing they doubt is the number, not the formatter.
///
/// **The rule is floor, towards negative infinity, never towards zero.**
///
/// Above zero that means only whole completed minutes count: a session 59
/// seconds old has earned nothing, and calling it "1 minute" would be the app
/// inventing credit. Below zero the same operator rounds 90 seconds of debt to
/// −2 rather than −1, which overstates what is owed.
///
/// Those look like opposite choices and are the same one: round the way that
/// does not flatter. An app whose whole premise is an honest number cannot have
/// a rounding rule that quietly makes the user look better than they are, in
/// either direction.
library;

/// Whole minutes, floored towards negative infinity.
int wholeMinutes(int seconds) => (seconds / 60).floor();

/// Minutes as a bare number, with a true minus sign for negatives.
///
/// The character is U+2212, not a hyphen: at the size the balance is set, a
/// hyphen reads as a dash beside the digits rather than as a sign.
String formatMinutes(int seconds) {
  final minutes = wholeMinutes(seconds);
  return minutes < 0 ? '−${minutes.abs()}' : '$minutes';
}

/// Minutes with a unit, for running text. `0m`, `9m`, `1h 06m`.
String formatDuration(int seconds) {
  final total = wholeMinutes(seconds).abs();
  final sign = seconds < 0 ? '−' : '';
  if (total < 60) return '$sign${total}m';
  return '$sign${total ~/ 60}h ${(total % 60).toString().padLeft(2, '0')}m';
}

/// Minutes as a clock reading, for the countdown. `1h06`.
String formatClock(int seconds) {
  final total = wholeMinutes(seconds).abs();
  final sign = seconds < 0 ? '−' : '';
  return '$sign${total ~/ 60}h${(total % 60).toString().padLeft(2, '0')}';
}
