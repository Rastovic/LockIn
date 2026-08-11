package com.jelena.tally

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import kotlin.math.abs

/**
 * Watches for the moment the balance runs out, and says so.
 *
 * **It delivers notices. It does not keep the count.** The authoritative
 * balance is recomputed in Dart from stored rows on every app open; this
 * service takes the last snapshot Dart wrote and subtracts usage since. If the
 * service dies, is killed by an OEM battery manager, or never runs at all, the
 * numbers are still exactly right the next time the app is opened. Only the
 * timely nudge was missed - a degraded experience rather than a broken product,
 * and the difference between three stars and one in this category.
 *
 * Polling backs off hard when nothing is being watched, because a tracker that
 * eats the battery gets uninstalled whatever its numbers say.
 */
class WatcherService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var snapshot: BalanceSnapshot
    private lateinit var reader: UsageReader

    private var lastRemaining: Int = Int.MAX_VALUE

    override fun onCreate() {
        super.onCreate()
        snapshot = BalanceSnapshot(applicationContext)
        reader = UsageReader(applicationContext)
        createChannels()
        startForeground(ONGOING_ID, buildOngoing("Tally is counting", null))
        schedule(FAST_MS)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // START_STICKY: Android restarts the service after it reclaims memory,
        // which is the common case on the cheap phones this audience owns.
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun schedule(delayMs: Long) {
        handler.postDelayed({ tick() }, delayMs)
    }

    private fun tick() {
        var nextDelay = SLOW_MS
        try {
            nextDelay = pollOnce()
        } catch (e: Exception) {
            // A failed poll must never take the service down with it. The next
            // one may well succeed, and the app's numbers do not depend on this
            // running at all.
            android.util.Log.w("Tally", "poll failed: ${e.message}")
        }
        schedule(nextDelay)
    }

    /** Returns how long to wait before the next poll. */
    private fun pollOnce(): Long {
        val packages = snapshot.watchedPackages
        val asOf = snapshot.asOfMillis

        if (packages.isEmpty() || asOf == 0L || !reader.hasAccess()) {
            updateOngoing("Tally is counting", null)
            return SLOW_MS
        }

        val now = System.currentTimeMillis()
        val spentSinceMs = reader
            .spans(asOf, now, packages)
            .sumOf { it.end - it.start }
        val spentSeconds = (spentSinceMs / 1000).toInt()

        val remaining = snapshot.spendableSeconds - spentSeconds
        val wasRemaining = lastRemaining
        lastRemaining = remaining

        updateOngoing(ongoingTitle(remaining), null)
        maybeNudge(remaining = remaining, previous = wasRemaining)

        // Poll quickly only while something is actually being spent. Otherwise
        // this is a background service burning battery to watch nothing happen.
        val active = spentSinceMs > 0 &&
            (now - asOf) < ACTIVE_WINDOW_MS &&
            remaining > FAR_UNDER_SECONDS
        return if (active) FAST_MS else SLOW_MS
    }

    private fun ongoingTitle(remaining: Int): String {
        val minutes = Math.floorDiv(remaining, 60)
        return when {
            minutes < 0 -> "Borrowing ${abs(minutes)} min"
            else -> "$minutes min left"
        }
    }

    /**
     * The three nudges, and only these three.
     *
     * Grace at zero, then -15, then -60. Each fires once per day, on the
     * crossing rather than on every poll: a service ticking every fifteen
     * seconds would otherwise send the same notice a hundred times.
     */
    private fun maybeNudge(remaining: Int, previous: Int) {
        if (!snapshot.notificationsEnabled) return
        val day = snapshot.dayKey
        if (day.isEmpty()) return
        snapshot.forgetOtherDays(day)

        data class Nudge(val tag: String, val at: Int, val title: String, val body: String)

        val nudges = listOf(
            Nudge(
                "grace", 0,
                "Balance empty",
                "Five minutes of grace, then you are borrowing.",
            ),
            Nudge(
                "debt15", -15 * 60,
                "15 minutes borrowed",
                "Tomorrow's allowance clears this before it fills your balance.",
            ),
            Nudge(
                "debt60", -60 * 60,
                "60 minutes borrowed",
                "That is the floor. The debt stops growing from here.",
            ),
        )

        for (nudge in nudges) {
            // Fire on the crossing only. Without the `previous` check a restart
            // mid-debt would re-send everything already passed.
            val crossed = previous > nudge.at && remaining <= nudge.at
            if (!crossed) continue
            if (snapshot.hasSent(day, nudge.tag)) continue
            snapshot.markSent(day, nudge.tag)
            post(nudge.tag.hashCode(), nudge.title, nudge.body)
        }
    }

    private fun post(id: Int, title: String, body: String) {
        val notification = NotificationCompat.Builder(this, CHANNEL_NUDGES)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(openApp())
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        manager().notify(id, notification)
    }

    private fun buildOngoing(title: String, body: String?): Notification =
        NotificationCompat.Builder(this, CHANNEL_ONGOING)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(openApp())
            .setOngoing(true)
            .setSilent(true)
            // Permanently on screen, so it is part of the design rather than a
            // side effect. Low importance keeps it out of the way.
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    private fun updateOngoing(title: String, body: String?) {
        manager().notify(ONGOING_ID, buildOngoing(title, body))
    }

    private fun openApp(): PendingIntent {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun manager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = manager()
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ONGOING,
                "Counting",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "The quiet notice that shows your balance."
                setShowBadge(false)
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_NUDGES,
                "Nudges",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Told once when your balance runs out."
            },
        )
    }

    companion object {
        private const val ONGOING_ID = 1001
        private const val CHANNEL_ONGOING = "tally.counting"
        private const val CHANNEL_NUDGES = "tally.nudges"

        /** While a watched app is in front. */
        private const val FAST_MS = 15_000L

        /** Everything else. */
        private const val SLOW_MS = 120_000L

        /** How stale a snapshot can be before fast polling stops paying off. */
        private const val ACTIVE_WINDOW_MS = 6 * 60 * 60 * 1000L

        /** Past the floor there is nothing left to warn about. */
        private const val FAR_UNDER_SECONDS = -70 * 60

        fun start(context: Context) {
            val intent = Intent(context, WatcherService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, WatcherService::class.java))
        }
    }
}
