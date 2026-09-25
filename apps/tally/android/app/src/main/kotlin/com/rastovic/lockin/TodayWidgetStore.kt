package com.rastovic.lockin

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import org.json.JSONArray

/**
 * What the home screen widget draws, written by Dart.
 *
 * The seam is deliberate: **Dart decides and
 * Android renders**. The rows arrive as finished strings, so nothing here
 * knows what a sticker id means, which tasks are habits, or how a day is
 * assembled. Adding a task kind or changing plan order needs no change in
 * Kotlin at all.
 */
class TodayWidgetStore(context: Context) {

    private val prefs =
        context.getSharedPreferences("tally.widget", Context.MODE_PRIVATE)

    /**
     * True between the end of the written day and the end of the one after,
     * when the widget draws the next day's plan Dart sent ahead of time.
     *
     * The day rolls over while the app is closed - that is the usual case,
     * not an edge - and a widget that goes blank every morning until the app
     * is opened is the bug this exists for. Every getter below reads the
     * next-day keys while this holds, so the provider and the list adapter
     * cannot disagree about which day they are drawing.
     */
    val showingNext: Boolean
        get() {
            val now = System.currentTimeMillis()
            val nextUntil = prefs.getLong(KEY_NEXT_VALID_UNTIL, 0L)
            return validUntilMillis != 0L && now >= validUntilMillis &&
                nextUntil != 0L && now < nextUntil
        }

    val dateLabel: String
        get() = prefs.getString(
            if (showingNext) KEY_NEXT_DATE else KEY_DATE,
            "",
        ) ?: ""

    val doneCount: Int
        get() = prefs.getInt(if (showingNext) KEY_NEXT_DONE else KEY_DONE, 0)

    val totalCount: Int
        get() = prefs.getInt(if (showingNext) KEY_NEXT_TOTAL else KEY_TOTAL, 0)

    val spendableSeconds: Int get() = prefs.getInt(KEY_SPENDABLE, 0)

    /**
     * False when usage access was never granted, and on the next day: its
     * balance depends on how yesterday closed, which only the app can work
     * out, so the widget says nothing rather than carrying the old figure.
     */
    val usageVisible: Boolean
        get() = !showingNext && prefs.getBoolean(KEY_USAGE, false)

    /** True once Dart has written anything, so a fresh widget can say so. */
    val hasData: Boolean get() = prefs.contains(KEY_DATE)

    /**
     * The instant this plan stops being today's, from Dart.
     *
     * Kotlin cannot work out when a day ends: the boundary is a setting, it is
     * 4am by default, and it moves with the timezone. So Dart sends the answer
     * and the widget does one comparison. Without it the widget would show
     * yesterday's tasks under today's date, which is the worst thing a widget
     * can do - confidently wrong rather than obviously broken.
     */
    val validUntilMillis: Long get() = prefs.getLong(KEY_VALID_UNTIL, 0L)

    /** Past both the written day and the next one Dart sent. */
    val isStale: Boolean
        get() = validUntilMillis != 0L &&
            System.currentTimeMillis() >= validUntilMillis &&
            !showingNext

    /**
     * The next instant the widget's day changes, or 0 when none is ahead.
     * An alarm is set for it, because the default 4am boundary is not a
     * moment Android announces.
     */
    val nextBoundaryMillis: Long
        get() {
            val now = System.currentTimeMillis()
            return listOf(
                validUntilMillis,
                prefs.getLong(KEY_NEXT_VALID_UNTIL, 0L),
            ).firstOrNull { it > now } ?: 0L
        }

    data class Row(val title: String, val done: Boolean, val glyph: String)

    val rows: List<Row>
        get() {
            val raw = prefs.getString(
                if (showingNext) KEY_NEXT_ROWS else KEY_ROWS,
                null,
            ) ?: return emptyList()
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).map { i ->
                    val item = array.getJSONObject(i)
                    Row(
                        title = item.optString("title"),
                        done = item.optBoolean("done"),
                        glyph = item.optString("glyph"),
                    )
                }
            } catch (e: Exception) {
                // Malformed rows cost the list, never a crash on the home
                // screen. A widget that throws is one the launcher stops
                // drawing entirely, and the user has no way to know why.
                emptyList()
            }
        }

    fun write(
        dateLabel: String,
        rowsJson: String,
        done: Int,
        total: Int,
        spendable: Int,
        usageVisible: Boolean,
        validUntil: Long,
        next: Next?,
    ) {
        val edit = prefs.edit()
            .putString(KEY_DATE, dateLabel)
            .putString(KEY_ROWS, rowsJson)
            .putInt(KEY_DONE, done)
            .putInt(KEY_TOTAL, total)
            .putInt(KEY_SPENDABLE, spendable)
            .putBoolean(KEY_USAGE, usageVisible)
            .putLong(KEY_VALID_UNTIL, validUntil)
        if (next == null) {
            // An older write's tomorrow must not outlive the day it belonged
            // after.
            edit.remove(KEY_NEXT_VALID_UNTIL)
        } else {
            edit.putString(KEY_NEXT_DATE, next.dateLabel)
                .putString(KEY_NEXT_ROWS, next.rowsJson)
                .putInt(KEY_NEXT_DONE, next.done)
                .putInt(KEY_NEXT_TOTAL, next.total)
                .putLong(KEY_NEXT_VALID_UNTIL, next.validUntil)
        }
        edit.apply()
    }

    /** The day after the written one, sent ahead by Dart. */
    data class Next(
        val dateLabel: String,
        val rowsJson: String,
        val done: Int,
        val total: Int,
        val validUntil: Long,
    )

    companion object {
        private const val KEY_DATE = "dateLabel"
        private const val KEY_ROWS = "rows"
        private const val KEY_DONE = "doneCount"
        private const val KEY_TOTAL = "totalCount"
        private const val KEY_SPENDABLE = "spendableSeconds"
        private const val KEY_USAGE = "usageVisible"
        private const val KEY_VALID_UNTIL = "validUntilMillis"
        private const val KEY_NEXT_DATE = "nextDateLabel"
        private const val KEY_NEXT_ROWS = "nextRows"
        private const val KEY_NEXT_DONE = "nextDoneCount"
        private const val KEY_NEXT_TOTAL = "nextTotalCount"
        private const val KEY_NEXT_VALID_UNTIL = "nextValidUntilMillis"

        /**
         * Redraws every placed instance.
         *
         * Both calls are needed and they do different things: the broadcast
         * rebuilds the frame, and [notifyAppWidgetViewDataChanged] is the only
         * thing that makes the list adapter re-read its rows. Sending just the
         * first leaves yesterday's tasks on screen under today's date.
         */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, TodayWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return

            manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
            TodayWidgetProvider.render(context, manager, ids)
        }
    }
}
