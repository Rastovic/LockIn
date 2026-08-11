import 'session.dart';

/// A pause taken during a focus block.
final class FocusPause {
  const FocusPause({required this.from, this.to});

  final DateTime from;

  /// Null while the pause is still running.
  final DateTime? to;

  bool get isOpen => to == null;

  int secondsAt(DateTime now) {
    final end = to ?? now;
    final seconds = end.difference(from).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }
}

/// A focus block in progress, or one that has finished.
///
/// **Wall-clock, never tick-accumulated.** A timer that counts its own ticks
/// drifts whenever the app is backgrounded, because Flutter stops delivering
/// them - so a 25 minute block spent with the screen off would credit far less
/// than 25 minutes. It is also trivially gameable in the other direction by a
/// clock that keeps firing while the phone sleeps.
///
/// Everything here is derived from [startedAt], the pauses, and the instant it
/// is asked about. The UI's ticker only decides how often to redraw; it never
/// decides what the number is.
final class FocusRun {
  const FocusRun({
    required this.id,
    required this.startedAt,
    required this.planned,
    this.taskId,
    this.pauses = const [],
    this.endedAt,
    this.extendedBy = Duration.zero,
    this.phoneDownRequested = false,
    this.screenUnlockedDuringBlock = false,
  });

  final String id;
  final DateTime startedAt;

  /// What the user asked for at the start.
  final Duration planned;

  final String? taskId;
  final List<FocusPause> pauses;

  /// Set once the block is over, however it ended.
  final DateTime? endedAt;

  /// Time added mid-block with +5 / +10 / +20.
  final Duration extendedBy;

  /// Whether this was started as a phone-down block.
  final bool phoneDownRequested;

  /// Whether the screen came on mid-block.
  ///
  /// A mid-block unlock still counts at 1.0x with an honest note. Cheating
  /// costs the bonus and nothing else, which is the whole design: the app does
  /// not punish, it just declines to pay extra.
  final bool screenUnlockedDuringBlock;

  bool get isRunning => endedAt == null;

  bool get isPaused => pauses.any((p) => p.isOpen);

  /// The full length being worked towards.
  Duration get target => planned + extendedBy;

  int totalPausedSeconds(DateTime now) =>
      pauses.fold(0, (sum, pause) => sum + pause.secondsAt(now));

  /// Seconds actually focused: wall-clock since the start, less any pauses.
  int elapsedSeconds(DateTime now) {
    final end = endedAt ?? now;
    final gross = end.difference(startedAt).inSeconds;
    final net = gross - totalPausedSeconds(now);
    return net < 0 ? 0 : net;
  }

  /// Seconds left on the clock. Never negative.
  int remainingSeconds(DateTime now) {
    final left = target.inSeconds - elapsedSeconds(now);
    return left < 0 ? 0 : left;
  }

  bool isComplete(DateTime now) => elapsedSeconds(now) >= target.inSeconds;

  /// Whether the phone-down bonus was earned.
  ///
  /// Requires the block to have been started as phone-down **and** the screen
  /// to have stayed off throughout.
  bool phoneDownEarned(DateTime now) =>
      phoneDownRequested && !screenUnlockedDuringBlock;

  FocusRun copyWith({
    List<FocusPause>? pauses,
    DateTime? endedAt,
    Duration? extendedBy,
    bool? screenUnlockedDuringBlock,
  }) =>
      FocusRun(
        id: id,
        startedAt: startedAt,
        planned: planned,
        taskId: taskId,
        pauses: pauses ?? this.pauses,
        endedAt: endedAt ?? this.endedAt,
        extendedBy: extendedBy ?? this.extendedBy,
        phoneDownRequested: phoneDownRequested,
        screenUnlockedDuringBlock:
            screenUnlockedDuringBlock ?? this.screenUnlockedDuringBlock,
      );

  /// Pauses the block. A second pause while already paused does nothing.
  FocusRun pause(DateTime at) {
    if (!isRunning || isPaused) return this;
    return copyWith(pauses: [...pauses, FocusPause(from: at)]);
  }

  /// Resumes. Resuming while not paused does nothing.
  FocusRun resume(DateTime at) {
    if (!isPaused) return this;
    return copyWith(
      pauses: [
        for (final pause in pauses)
          if (pause.isOpen) FocusPause(from: pause.from, to: at) else pause,
      ],
    );
  }

  /// Adds time mid-block.
  FocusRun extend(Duration by) =>
      isRunning ? copyWith(extendedBy: extendedBy + by) : this;

  /// Ends the block, closing any open pause so the elapsed total stops moving.
  FocusRun finish(DateTime at) {
    if (!isRunning) return this;
    return copyWith(
      endedAt: at,
      pauses: [
        for (final pause in pauses)
          if (pause.isOpen) FocusPause(from: pause.from, to: at) else pause,
      ],
    );
  }

  /// Turns a finished block into what the ledger consumes.
  ///
  /// **The paused time is removed by shortening the span**, not by passing the
  /// real end instant, so the engine credits only the seconds actually focused.
  /// Giving up early is not a failure state: it simply produces a shorter
  /// session, and one under the minimum earning block earns nothing without
  /// anything special being said about it.
  FocusSession? toSession(DateTime now) {
    if (isRunning) return null;
    final seconds = elapsedSeconds(now);
    if (seconds <= 0) return null;
    return FocusSession(
      id: id,
      startedAt: startedAt,
      endedAt: startedAt.add(Duration(seconds: seconds)),
      taskId: taskId,
      phoneDownVerified: phoneDownEarned(now),
    );
  }

  /// `MM:SS`, or `H:MM:SS` past an hour.
  static String format(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final hours = s ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    final secs = s % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }
}
