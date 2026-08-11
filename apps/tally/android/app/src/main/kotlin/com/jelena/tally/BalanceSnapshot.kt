package com.jelena.tally

import android.content.Context
import android.content.SharedPreferences

/**
 * What Dart tells the watcher, so the watcher never has to know the rules.
 *
 * The plan's architecture rule is that **the ledger is derived and the service
 * exists only to deliver timely notices, not to keep the count**. This is the
 * seam that makes that true: Dart recomputes the authoritative balance from
 * stored rows and writes it here with the instant it was true; the service
 * subtracts usage since that instant and nothing more.
 *
 * The consequence is the one the plan wants. If an OEM battery manager kills
 * the service for six hours, the numbers are still exactly right the moment the
 * app is opened. Only the nudge was missed.
 */
class BalanceSnapshot(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("tally.watcher", Context.MODE_PRIVATE)

    /** Spendable seconds as of [asOfMillis], straight from the Dart engine. */
    val spendableSeconds: Int get() = prefs.getInt(KEY_SPENDABLE, 0)

    val asOfMillis: Long get() = prefs.getLong(KEY_AS_OF, 0L)

    /** Packages the user chose to price. Empty means nothing to watch. */
    val watchedPackages: Set<String>
        get() = prefs.getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()

    /** Free seconds left before borrowing starts, at [asOfMillis]. */
    val graceSeconds: Int get() = prefs.getInt(KEY_GRACE, 0)

    /** The day the snapshot belongs to, so nudge markers reset with the day. */
    val dayKey: String get() = prefs.getString(KEY_DAY, "") ?: ""

    val notificationsEnabled: Boolean
        get() = prefs.getBoolean(KEY_NOTIFY, true)

    fun write(
        spendable: Int,
        grace: Int,
        asOf: Long,
        packages: Set<String>,
        day: String,
        notify: Boolean,
    ) {
        prefs.edit()
            .putInt(KEY_SPENDABLE, spendable)
            .putInt(KEY_GRACE, grace)
            .putLong(KEY_AS_OF, asOf)
            .putStringSet(KEY_PACKAGES, packages)
            .putString(KEY_DAY, day)
            .putBoolean(KEY_NOTIFY, notify)
            .apply()
    }

    /**
     * Whether a nudge with this tag has already gone out today.
     *
     * Kept per day and per tag rather than as a running count, so the grace
     * warning cannot be crowded out by two debt notices, and a reboot does not
     * hand out a fresh set.
     */
    fun hasSent(day: String, tag: String): Boolean =
        prefs.getBoolean("sent.$day.$tag", false)

    fun markSent(day: String, tag: String) {
        prefs.edit().putBoolean("sent.$day.$tag", true).apply()
    }

    /** Drops other days' markers so the map does not grow without limit. */
    fun forgetOtherDays(currentDay: String) {
        val editor = prefs.edit()
        for (key in prefs.all.keys) {
            if (key.startsWith("sent.") && !key.startsWith("sent.$currentDay.")) {
                editor.remove(key)
            }
        }
        editor.apply()
    }

    private companion object {
        const val KEY_SPENDABLE = "spendableSeconds"
        const val KEY_GRACE = "graceSeconds"
        const val KEY_AS_OF = "asOfMillis"
        const val KEY_PACKAGES = "watchedPackages"
        const val KEY_DAY = "dayKey"
        const val KEY_NOTIFY = "notificationsEnabled"
    }
}
