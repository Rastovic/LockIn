package com.rastovic.lockin

import android.content.Context
import org.json.JSONArray

/**
 * What the app blocker needs to know, written by Dart.
 *
 * The same seam as the widget: **Dart keeps the count, Kotlin only subtracts.**
 * Dart recomputes the authoritative balance from stored rows and writes it with
 * the instant the usage behind it was read. The blocker takes usage since that
 * instant off it and nothing more, so it never needs the ledger's rules - earn
 * rate, allowance, debt floor - and cannot disagree with the app about them.
 */
class BlockStore(context: Context) {

    private val prefs =
        context.getSharedPreferences("tally.block", Context.MODE_PRIVATE)

    /** The switch in the app. The system accessibility switch is separate. */
    val enabled: Boolean get() = prefs.getBoolean(KEY_ENABLED, false)

    /**
     * True blocks; false only reminds, and the page offers "Continue anyway".
     * Time after continuing is counted like any other, so it lands as debt.
     */
    val hard: Boolean get() = prefs.getBoolean(KEY_HARD, true)

    val spendableSeconds: Int get() = prefs.getInt(KEY_SPENDABLE, 0)

    /**
     * The app the user chose to continue into, in remind mode.
     *
     * Held until they switch to a different app, so the reminder does not
     * come straight back on the relaunch that follows "Continue anyway", but
     * does come back the next time they open it.
     */
    var passPackage: String?
        get() = prefs.getString(KEY_PASS, null)
        set(value) {
            prefs.edit().putString(KEY_PASS, value).apply()
        }

    /** When the usage behind [spendableSeconds] was last read. */
    val asOfMillis: Long get() = prefs.getLong(KEY_AS_OF, 0L)

    /**
     * When today's figure stops being today's.
     *
     * Past it the app may owe a fresh allowance, and only Dart can work that
     * out. The blocker keeps subtracting from the old figure, which can only
     * err towards blocking, and the block screen says opening LockIn refreshes
     * it. Guessing the new day's balance in Kotlin would be a second copy of
     * the ledger.
     */
    val validUntilMillis: Long get() = prefs.getLong(KEY_VALID_UNTIL, 0L)

    val isStale: Boolean
        get() = validUntilMillis != 0L &&
            System.currentTimeMillis() >= validUntilMillis

    val packages: Set<String>
        get() {
            val raw = prefs.getString(KEY_PACKAGES, null) ?: return emptySet()
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).map { array.getString(it) }.toSet()
            } catch (e: Exception) {
                // A malformed list blocks nothing. Failing open is the right
                // side here: a blocker that covers the wrong app is far worse
                // than one that misses a minute.
                emptySet()
            }
        }

    /**
     * Seconds left right now: Dart's figure minus watched-app time since.
     *
     * Merged spans, so two watched apps on screen at once cost one minute per
     * minute, the same rule the app counts by.
     */
    fun remainingSeconds(reader: UsageReader, now: Long): Long {
        val watched = packages
        val asOf = asOfMillis
        if (watched.isEmpty() || asOf == 0L || !reader.hasAccess()) {
            return spendableSeconds.toLong()
        }
        val spentMillis = reader.spans(asOf, now, watched)
            .sumOf { it.end - it.start }
        return spendableSeconds - spentMillis / 1000
    }

    fun write(
        enabled: Boolean,
        hard: Boolean,
        packagesJson: String,
        spendableSeconds: Int,
        asOfMillis: Long,
        validUntilMillis: Long,
    ) {
        prefs.edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putBoolean(KEY_HARD, hard)
            .putString(KEY_PACKAGES, packagesJson)
            .putInt(KEY_SPENDABLE, spendableSeconds)
            .putLong(KEY_AS_OF, asOfMillis)
            .putLong(KEY_VALID_UNTIL, validUntilMillis)
            .apply()
    }

    private companion object {
        const val KEY_ENABLED = "enabled"
        const val KEY_HARD = "hard"
        const val KEY_PASS = "passPackage"
        const val KEY_PACKAGES = "packages"
        const val KEY_SPENDABLE = "spendableSeconds"
        const val KEY_AS_OF = "asOfMillis"
        const val KEY_VALID_UNTIL = "validUntilMillis"
    }
}
