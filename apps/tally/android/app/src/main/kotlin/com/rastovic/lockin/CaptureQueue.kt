package com.jelena.tally

import android.content.Context
import org.json.JSONArray

/**
 * Things typed into the capture widget, waiting for Dart to turn them into
 * tasks.
 *
 * **Android collects, Dart decides** - the same rule as everywhere else here,
 * pointed the other way. This holds plain strings and nothing else: no ids, no
 * kinds, no timestamps that matter. Kotlin is not writing tasks, it is holding
 * words until the part of the app that knows what a task is can run.
 *
 * That is what keeps the single-writer rule intact while making capture
 * instant. Opening Flutter to save one line would cost a cold start, and a
 * capture tool slower than remembering the thing is one nobody uses.
 */
class CaptureQueue(context: Context) {

    private val prefs =
        context.getSharedPreferences("tally.capture", Context.MODE_PRIVATE)

    val pending: List<String>
        get() {
            val raw = prefs.getString(KEY_ITEMS, null) ?: return emptyList()
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).map { array.getString(it) }
            } catch (e: Exception) {
                // A malformed queue costs the queue, never the launch.
                emptyList()
            }
        }

    val count: Int get() = pending.size

    /** Appends one captured line. Blank input is not a capture. */
    fun add(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return
        write(pending + trimmed)
    }

    /**
     * Hands everything to Dart and empties the queue.
     *
     * Read and clear together so a capture arriving mid-drain cannot fall
     * between them: anything written after this returns is simply in the next
     * drain.
     */
    fun drain(): List<String> {
        val items = pending
        if (items.isNotEmpty()) write(emptyList())
        return items
    }

    private fun write(items: List<String>) {
        prefs.edit().putString(KEY_ITEMS, JSONArray(items).toString()).apply()
    }

    companion object {
        private const val KEY_ITEMS = "items"
    }
}
