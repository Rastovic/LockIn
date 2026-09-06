package com.rastovic.lockin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * The running block, counting down outside the app.
 *
 * **Android renders the countdown, not us.** The notification carries the
 * instant the block ends and a flag saying "count towards it"; SystemUI ticks
 * the digits itself. Nothing here wakes up per second, nothing polls, and the
 * numbers keep falling while the app's process is dead - which is the normal
 * state during a block, because the whole point is to put the phone down.
 *
 * Two surfaces, from one notification:
 *
 *  - **The shade.** A chronometer counting down, the way the stock timer looks.
 *    Works everywhere back to the minimum this app supports.
 *  - **The status bar chip**, next to the camera. Android 16 only, and it is the
 *    system's decision rather than ours: an app cannot ask to be up there. What
 *    it can do is post something with the characteristics the system promotes -
 *    ongoing, coloured, a progress style, and a short piece of critical text -
 *    and that text is what the chip shows. Below 16 there is no public way to
 *    draw next to the camera at all, so the shade is the whole story there.
 */
object FocusNotice {

    /**
     * Fixed id: there is one block at a time, and a stale notice from a block
     * that ended must be replaced rather than joined.
     */
    private const val ID = 1002
    private const val CHANNEL = "tally.focus"

    /**
     * Shows or updates the countdown.
     *
     * [endsAtMillis] is the wall-clock instant the block ends, which is what
     * makes this survive process death: it is an absolute time, not a duration
     * that would need someone alive to decrement it.
     */
    fun show(
        context: Context,
        endsAtMillis: Long,
        remainingSeconds: Int,
        totalSeconds: Int,
        taskTitle: String?,
        paused: Boolean,
    ) {
        createChannel(context)

        val title = taskTitle?.takeIf { it.isNotBlank() } ?: "Focusing"
        val builder = Notification.Builder(context, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentIntent(openApp(context))
            .setOngoing(true)
            // The block is not news. It is alerted once when it starts and then
            // updates silently, or every screen unlock during a 45 minute block
            // is another buzz.
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            // Colourised is part of what the system looks for when deciding
            // whether something belongs in the status bar, and it also reads as
            // an activity in progress rather than a message.
            .setColorized(true)

        if (paused) {
            // A paused block has no instant to count towards, and a chronometer
            // pointed at a stale end would tick down into a time that is no
            // longer coming. Say the state instead.
            builder.setContentText("Paused - ${minutesLabel(remainingSeconds)} left")
        } else {
            builder
                .setWhen(endsAtMillis)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                // Android clears the notice itself when the block's time is up.
                // Without this, a block that finished while the app was dead
                // would leave a countdown at 00:00 on screen until the app next
                // ran.
                .setTimeoutAfter(maxOf(1_000L, remainingSeconds * 1000L))
        }

        if (Build.VERSION.SDK_INT >= 36) {
            promote(builder, remainingSeconds, totalSeconds, paused)
        }

        manager(context).notify(ID, builder.build())
    }

    fun hide(context: Context) = manager(context).cancel(ID)

    /**
     * Gives the notification what Android 16 promotes to the status bar.
     *
     * The short critical text *is* the chip: a handful of characters, so it is
     * "24m" rather than "24 minutes left". A progress style alongside it is what
     * marks this as an activity with a shape rather than a message, and it draws
     * the bar in the shade for free.
     *
     * Not a request and not a guarantee. The user can turn promotion off per
     * app, and the system decides. Everything above still works when it says no.
     */
    private fun promote(
        builder: Notification.Builder,
        remainingSeconds: Int,
        totalSeconds: Int,
        paused: Boolean,
    ) {
        val total = if (totalSeconds > 0) totalSeconds else 1
        val done = (total - remainingSeconds).coerceIn(0, total)
        // The maximum is not set directly: a ProgressStyle's range is the sum of
        // its segments, so the whole block is one segment as long as itself and
        // the progress is how much of it has been worked.
        builder.setStyle(
            Notification.ProgressStyle()
                .setProgressSegments(
                    listOf(Notification.ProgressStyle.Segment(total)),
                )
                .setProgress(done),
        )
        builder.setShortCriticalText(
            if (paused) "Paused" else shortLabel(remainingSeconds),
        )
    }

    /** Chip-sized: "45m", "1h 5m", "40s" in the last minute. */
    private fun shortLabel(seconds: Int): String {
        if (seconds < 60) return "${seconds.coerceAtLeast(0)}s"
        val minutes = seconds / 60
        if (minutes < 60) return "${minutes}m"
        val hours = minutes / 60
        val rest = minutes % 60
        return if (rest == 0) "${hours}h" else "${hours}h ${rest}m"
    }

    private fun minutesLabel(seconds: Int): String {
        val minutes = (seconds + 59) / 60
        return if (minutes == 1) "1 minute" else "$minutes minutes"
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        manager(context).createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                "Focus block",
                // Low: it is a thing on screen for the length of a block, not an
                // interruption. The end of the block is a separate notification
                // and that one is allowed to make noise.
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "The countdown while a focus block is running."
                setShowBadge(false)
            },
        )
    }

    private fun manager(context: Context): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun openApp(context: Context): PendingIntent {
        val intent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            2,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
