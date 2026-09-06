import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notifier.dart';
import 'policy.dart';

/// One notification channel.
///
/// Android groups notifications by channel and lets the user silence a channel
/// without silencing the app. That is worth having: someone who finds the
/// nudges too much can turn off exactly those and keep their reminders.
final class NudgeChannel {
  const NudgeChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    this.usage = AudioAttributesUsage.notification,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;

  /// Which audio stream the channel plays on. Alarm usage survives a silenced
  /// ringer; notification usage does not.
  final AudioAttributesUsage usage;

  static const nudges = NudgeChannel(
    id: 'nudges',
    name: 'Nudges',
    description: 'Timely notices, such as running low or going negative.',
    importance: Importance.defaultImportance,
  );

  static const reminders = NudgeChannel(
    id: 'reminders',
    name: 'Reminders',
    description: 'Reminders you scheduled yourself.',
    importance: Importance.high,
  );

  /// The channel a timer rings on.
  ///
  /// **Alarm usage, not notification usage.** That is the whole difference:
  /// it plays on the alarm stream, at alarm volume, so it is heard through a
  /// silenced ringer and with the phone face down - which is exactly the
  /// state a focus block puts the phone in. At [Importance.max] it also
  /// arrives as a heads-up rather than a line in the shade.
  ///
  /// A separate id from [reminders] because **a channel is immutable once
  /// created**: Android ignores every later change to its importance, sound
  /// and vibration, so making an existing channel louder is impossible and
  /// the only route is a new one.
  static const alarms = NudgeChannel(
    id: 'alarms',
    name: 'Timer alarms',
    description: 'The end of a timer you started.',
    importance: Importance.max,
    usage: AudioAttributesUsage.alarm,
  );

  static const milestones = NudgeChannel(
    id: 'milestones',
    name: 'Milestones',
    description: 'Occasional notices, such as reaching a savings threshold.',
    importance: Importance.low,
  );

  static NudgeChannel forKind(NudgeKind kind) => switch (kind) {
        NudgeKind.scheduled => reminders,
        NudgeKind.alarm => alarms,
        NudgeKind.nudge => nudges,
        NudgeKind.milestone => milestones,
      };

  static const all = [nudges, reminders, milestones, alarms];
}

/// The real [Notifier], on `flutter_local_notifications`.
///
/// The only file in this package that touches a plugin. Everything worth
/// testing lives in [NudgePolicy], which is pure.
final class LocalNotifier implements Notifier {
  LocalNotifier({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialised = false;

  @override
  Future<void> initialise() async {
    if (_initialised) return;

    // Scheduling needs a real timezone database, not the device offset: an
    // alarm set for 21:00 must survive a DST change without drifting an hour.
    tz_data.initializeTimeZones();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Asked for explicitly later, with the reason on screen first.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in NudgeChannel.all) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          channel.name,
          description: channel.description,
          importance: channel.importance,
          audioAttributesUsage: channel.usage,
        ),
      );
    }

    _initialised = true;
  }

  @override
  Future<NotificationPermission> permission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? false
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      // iOS cannot report state without requesting, so an unknown state is
      // reported as not-yet-determined rather than guessed at.
      return NotificationPermission.notDetermined;
    }
    return NotificationPermission.denied;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: true);
    return granted ?? false
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }

  @override
  Future<void> show(Nudge nudge) async {
    await initialise();
    await _plugin.show(
      nudge.id,
      nudge.title,
      nudge.body,
      _detailsFor(nudge),
      payload: nudge.tag,
    );
  }

  @override
  Future<void> schedule(Nudge nudge) async {
    await initialise();
    // An instant that has already gone is nothing to post, not an error.
    //
    // The plugin throws on a past date, and a throw here reaches whatever was
    // reconciling state and takes that down with it. Callers restore alarms
    // for things that were running when the process died, so a time in the
    // past is an ordinary case for them - it means the thing finished while
    // the app was away, and the caller has its own handling for that.
    if (!nudge.at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      nudge.id,
      nudge.title,
      nudge.body,
      tz.TZDateTime.from(nudge.at, tz.local),
      _detailsFor(nudge),
      androidScheduleMode: await _scheduleMode(),
      payload: nudge.tag,
    );
  }

  @override
  Future<void> scheduleDaily(Nudge nudge) async {
    await initialise();
    await _plugin.zonedSchedule(
      nudge.id,
      nudge.title,
      nudge.body,
      tz.TZDateTime.from(nudge.at, tz.local),
      _detailsFor(nudge),
      androidScheduleMode: await _scheduleMode(),
      // The clock time is what repeats. Matching on time components rather
      // than adding 24 hours is what keeps a 21:00 reminder at 21:00 through
      // a DST change instead of sliding an hour.
      matchDateTimeComponents: DateTimeComponents.time,
      payload: nudge.tag,
    );
  }

  /// Exact when Android allows it, inexact when it does not.
  ///
  /// A focus block is a timer, and a timer Android batches at its convenience
  /// is not one: inexact alarms can be deferred by many minutes, which for a
  /// 45 minute block reads as "it did not go off".
  ///
  /// Not simply always exact, because the permission is not always there. It
  /// is granted by default on Android 13, revocable by the user, and on 14 it
  /// is only automatic for apps whose whole purpose is alarms. Asking every
  /// time and falling back means the block still rings either way, just less
  /// punctually.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      final exact = await android.canScheduleExactNotifications() ?? false;
      return exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } on Object {
      // An older OS with no such concept, or an OEM that refuses the query.
      // Inexact always works.
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  @override
  Future<bool> canScheduleExactly() async =>
      await _scheduleMode() == AndroidScheduleMode.exactAllowWhileIdle;

  @override
  Future<bool> requestExactScheduling() => requestExactAlarms();

  /// Sends the user to the exact-alarm screen, if there is one.
  ///
  /// Returns whether exact alarms are usable afterwards.
  Future<bool> requestExactAlarms() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    try {
      await android.requestExactAlarmsPermission();
      return await android.canScheduleExactNotifications() ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<int>> pending() async {
    final pending = await _plugin.pendingNotificationRequests();
    return [for (final request in pending) request.id];
  }

  NotificationDetails _detailsFor(Nudge nudge) {
    final channel = NudgeChannel.forKind(nudge.kind);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: switch (nudge.kind) {
          NudgeKind.alarm => Priority.max,
          NudgeKind.scheduled => Priority.high,
          NudgeKind.nudge => Priority.defaultPriority,
          NudgeKind.milestone => Priority.low,
        },
        // Repeated on the notification as well as the channel: the channel
        // decides how Android *may* treat it, these decide how this one is
        // built. A timer marked as an alarm sorts above ordinary notices and
        // is exempt from some batching.
        category: nudge.kind == NudgeKind.alarm
            ? AndroidNotificationCategory.alarm
            : null,
        audioAttributesUsage: channel.usage,
        // The body is one plain sentence, so it must not be truncated to a
        // fragment that reads as an error.
        styleInformation: BigTextStyleInformation(nudge.body),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }
}
