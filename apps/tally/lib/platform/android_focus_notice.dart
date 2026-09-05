import 'package:flutter/services.dart';
import 'package:tally_engine/tally_engine.dart';

/// The running block, counting down where the phone already shows timers.
///
/// **Android renders the digits.** This hands over the instant the block ends
/// and a flag saying "count towards it"; SystemUI ticks it. So the countdown
/// keeps falling with the app's process dead, which is the normal state during a
/// block - the whole point is to put the phone down.
///
/// Separate from the end-of-block alarm, which is a different thing with a
/// different job: that one rings once, this one is on screen the whole time and
/// makes no sound. The alarm exists so the end is not missed; this exists so the
/// remaining time can be seen without opening anything.
final class AndroidFocusNotice {
  const AndroidFocusNotice({
    this.channel = const MethodChannel('tally/usage'),
  });

  final MethodChannel channel;

  /// Shows or updates the countdown for [run].
  ///
  /// [now] comes from the caller's clock rather than being read here, so the end
  /// instant this sends is the same one the rest of the app is reasoning about.
  Future<void> show({
    required FocusRun run,
    required DateTime now,
    String? taskTitle,
  }) async {
    final remaining = run.remainingSeconds(now);
    try {
      await channel.invokeMethod<void>('showFocusNotice', {
        'endsAtMillis':
            now.add(Duration(seconds: remaining)).millisecondsSinceEpoch,
        'remainingSeconds': remaining,
        'totalSeconds': run.target.inSeconds,
        'taskTitle': taskTitle,
        'paused': run.isPaused,
      });
    } on PlatformException {
      // A countdown that could not be posted costs the user a glance at the
      // shade. The block itself is unaffected, and so is the alarm at the end.
    } on MissingPluginException {
      // No implementation on this platform, which is the web preview.
    }
  }

  Future<void> hide() async {
    try {
      await channel.invokeMethod<void>('hideFocusNotice');
    } on PlatformException {
      // Nothing to do about it, and nothing depends on it.
    } on MissingPluginException {
      // As above.
    }
  }
}
