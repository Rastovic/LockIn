package com.rastovic.lockin

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Process
import android.provider.Settings

/**
 * Reads foreground usage from [UsageStatsManager].
 *
 * This is the part Flutter cannot do, and the part the whole app rests on. The
 * contract it owes Dart is narrow on purpose: closed spans of foreground time,
 * already merged, for a window and a set of packages.
 *
 * ## What makes this hard
 *
 * The event stream is routinely malformed and that is normal input, not an
 * error path:
 *
 *  - a `RESUMED` with no matching `PAUSED`, because the process was killed
 *  - a `PAUSED` with no `RESUMED`, because the query window began mid-session
 *  - two `RESUMED` in a row for the same package
 *  - events slightly out of order
 *
 * Every one of those is handled here rather than being pushed to Dart, so the
 * iOS implementation is not obliged to reproduce Android's quirks.
 */
class UsageReader(private val context: Context) {

    /** A closed interval of foreground time. */
    data class Span(val packageName: String, val start: Long, val end: Long)

    /** Whether the user has granted usage access in system Settings. */
    fun hasAccess(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        )
        // A granted-by-default mode still has to be confirmed by an actual
        // permission check: some OEMs report DEFAULT while refusing the data.
        return if (mode == AppOpsManager.MODE_DEFAULT) {
            context.checkCallingOrSelfPermission(
                android.Manifest.permission.PACKAGE_USAGE_STATS,
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            mode == AppOpsManager.MODE_ALLOWED
        }
    }

    /**
     * Opens the usage-access screen.
     *
     * There is no in-app dialog for a special access, so the app sends the user
     * out and re-checks on return. Some devices do not have the per-app screen,
     * hence the fallback to the list.
     */
    fun openAccessSettings() {
        val intents = listOf(
            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = android.net.Uri.parse("package:${context.packageName}")
            },
            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS),
        )
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                return
            }
        }
    }

    /**
     * Foreground spans for [packages] between [from] and [to], in epoch millis.
     *
     * Spans are clamped to the window, merged across packages, and returned in
     * order. Merging here rather than in Dart is deliberate: picture-in-picture
     * puts two watched apps in front at once, and a minute of the user's life
     * is one minute however many apps were on screen.
     */
    fun spans(from: Long, to: Long, packages: Set<String>): List<Span> {
        if (packages.isEmpty() || to <= from) return emptyList()
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE)
            as? UsageStatsManager ?: return emptyList()

        val events = manager.queryEvents(from, to)
        val open = HashMap<String, Long>()
        val spans = ArrayList<Span>()
        val event = UsageEvents.Event()

        fun close(pkg: String, at: Long) {
            val started = open.remove(pkg) ?: return
            if (at > started) spans.add(Span(pkg, started, at))
        }

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    if (packages.contains(pkg)) {
                        // A second resume means the pause was lost. Close the
                        // old span here rather than discarding either.
                        close(pkg, event.timeStamp)
                        open[pkg] = event.timeStamp
                    }
                }

                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.ACTIVITY_STOPPED,
                -> close(pkg, event.timeStamp)

                // The screen going off or the device locking ends every open
                // span: a watched app "in front" behind a lock screen is not
                // being scrolled.
                UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                UsageEvents.Event.KEYGUARD_SHOWN,
                -> {
                    for (key in open.keys.toList()) close(key, event.timeStamp)
                }
            }
        }

        // Anything still open at the end of the window is closed there. The
        // user may still be in the app; the next reconcile picks up the rest.
        for (key in open.keys.toList()) close(key, to)

        return merge(spans.map { it.copy(start = maxOf(it.start, from), end = minOf(it.end, to)) }
            .filter { it.end > it.start })
    }

    /** Reduces overlapping spans to the wall-clock time any of them covered. */
    private fun merge(spans: List<Span>): List<Span> {
        if (spans.isEmpty()) return emptyList()
        val sorted = spans.sortedBy { it.start }
        val merged = ArrayList<Span>()
        var current = sorted.first()

        for (span in sorted.drop(1)) {
            current = if (span.start <= current.end) {
                current.copy(end = maxOf(current.end, span.end))
            } else {
                merged.add(current)
                span
            }
        }
        merged.add(current)
        return merged
    }

    /**
     * Apps worth offering in the picker, with their recent foreground time.
     *
     * Launchable apps only, and never this one: Tally watching itself is never
     * billable, and it is excluded here as well as in the engine because a rule
     * enforced in one place is a rule waiting to be bypassed.
     */
    fun installedApps(recentDays: Int, now: Long): List<Map<String, Any>> {
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE)
            as? UsageStatsManager ?: return emptyList()
        val pm = context.packageManager

        val since = now - recentDays * 24L * 60L * 60L * 1000L
        val totals = HashMap<String, Long>()
        for (span in spansForAll(manager, since, now)) {
            totals[span.packageName] =
                (totals[span.packageName] ?: 0L) + (span.end - span.start)
        }

        val launchable = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            .filter { it.packageName != context.packageName }
            .filter { pm.getLaunchIntentForPackage(it.packageName) != null }

        return launchable.map { info ->
            mapOf(
                "packageName" to info.packageName,
                "label" to pm.getApplicationLabel(info).toString(),
                "recentSeconds" to ((totals[info.packageName] ?: 0L) / 1000L).toInt(),
                "isSystem" to ((info.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
            )
        }.sortedByDescending { it["recentSeconds"] as Int }
    }

    /** Per-package spans with no package filter, used only for the picker. */
    private fun spansForAll(
        manager: UsageStatsManager,
        from: Long,
        to: Long,
    ): List<Span> {
        val events = manager.queryEvents(from, to)
        val open = HashMap<String, Long>()
        val spans = ArrayList<Span>()
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    open.remove(pkg)?.let { started ->
                        if (event.timeStamp > started) {
                            spans.add(Span(pkg, started, event.timeStamp))
                        }
                    }
                    open[pkg] = event.timeStamp
                }

                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.ACTIVITY_STOPPED,
                -> open.remove(pkg)?.let { started ->
                    if (event.timeStamp > started) {
                        spans.add(Span(pkg, started, event.timeStamp))
                    }
                }
            }
        }
        return spans
    }
}
