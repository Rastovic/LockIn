package com.jelena.tally

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import org.json.JSONArray

/**
 * What the home screen widget draws, written by Dart.
 *
 * The same seam as [BalanceSnapshot], for the same reason: **Dart decides and
 * Android renders**. The rows arrive as finished strings, so nothing here
 * knows what a sticker id means, which tasks are habits, or how a day is
 * assembled. Adding a task kind or changing plan order needs no change in
 * Kotlin at all.
 */
class TodayWidgetStore(context: Context) {

    private val prefs =
        context.getSharedPreferences("tally.widget", Context.MODE_PRIVATE)

    val dateLabel: String get() = prefs.getString(KEY_DATE, "") ?: ""

    val doneCount: Int get() = prefs.getInt(KEY_DONE, 0)

    val totalCount: Int get() = prefs.getInt(KEY_TOTAL, 0)

    val spendableSeconds: Int get() = prefs.getInt(KEY_SPENDABLE, 0)

    /** False when usage access was never granted. */
    val usageVisible: Boolean get() = prefs.getBoolean(KEY_USAGE, false)

    /** True once Dart has written anything, so a fresh widget can say so. */
    val hasData: Boolean get() = prefs.contains(KEY_DATE)

    data class Row(val title: String, val done: Boolean, val glyph: String)

    val rows: List<Row>
        get() {
            val raw = prefs.getString(KEY_ROWS, null) ?: return emptyList()
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
    ) {
        prefs.edit()
            .putString(KEY_DATE, dateLabel)
            .putString(KEY_ROWS, rowsJson)
            .putInt(KEY_DONE, done)
            .putInt(KEY_TOTAL, total)
            .putInt(KEY_SPENDABLE, spendable)
            .putBoolean(KEY_USAGE, usageVisible)
            .apply()
    }

    companion object {
        private const val KEY_DATE = "dateLabel"
        private const val KEY_ROWS = "rows"
        private const val KEY_DONE = "doneCount"
        private const val KEY_TOTAL = "totalCount"
        private const val KEY_SPENDABLE = "spendableSeconds"
        private const val KEY_USAGE = "usageVisible"

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
