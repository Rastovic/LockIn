package com.jelena.tally

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts the watcher after a reboot.
 *
 * Android drops running services on restart, and a tracker that silently stops
 * watching after the phone reboots is the single most common one-star review in
 * this category: "stopped tracking".
 *
 * It only starts if there is something to watch. Starting a foreground service
 * with a permanent notification for a user who never picked an app would be a
 * needless intrusion.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        val snapshot = BalanceSnapshot(context)
        if (snapshot.watchedPackages.isEmpty()) return
        WatcherService.start(context)
    }
}
