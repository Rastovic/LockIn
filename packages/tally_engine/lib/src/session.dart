/// A completed focus block: the only thing in the app that earns minutes.
///
/// Ticking a task earns too, since 2026-09-24, but not through a second
/// input: the app banks the unfocused part of the task's estimate as an
/// ordinary 1.0x session, so the engine still knows only sessions.
final class FocusSession {
  FocusSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    this.taskId,
    this.phoneDownVerified = false,
  }) : assert(!endedAt.isBefore(startedAt));

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;

  /// The task this block was worked against, if any.
  final String? taskId;

  /// True when the screen stayed off for the whole block.
  ///
  /// Verified from screen-state events, with a 10 second allowance for the
  /// lock-screen glance. A mid-block unlock still counts at 1.0x with an honest
  /// note, so cheating costs the bonus and nothing else.
  final bool phoneDownVerified;

  int get seconds => endedAt.difference(startedAt).inSeconds;

  @override
  String toString() => 'FocusSession($id, ${seconds}s, '
      'phoneDown: $phoneDownVerified)';
}

/// Minutes moved between the spendable balance and savings, by hand.
final class SavingsTransfer {
  const SavingsTransfer({
    required this.id,
    required this.at,
    required this.seconds,
    required this.toSavings,
  });

  final String id;
  final DateTime at;

  /// Always a positive magnitude. [toSavings] carries the direction.
  final int seconds;

  /// True moves balance into savings, false withdraws savings to cover a debt.
  final bool toSavings;
}

/// Savings spent on something that is not a screen.
///
/// The counterweight to the whole app. Without it Tally is only a scold.
///
/// **Burned, not converted.** A treat can never become scroll minutes, under
/// any sequence of transfers. That is asserted as a test, because it is the one
/// loophole that would turn savings into a laundering route back into the
/// spendable balance.
final class Treat {
  const Treat({
    required this.id,
    required this.at,
    required this.seconds,
    required this.label,
  });

  final String id;
  final DateTime at;
  final int seconds;
  final String label;
}
