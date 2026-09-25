package com.rastovic.lockin

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager

/**
 * Covers a watched app once the minutes are gone.
 *
 * **It reads one thing: which app just came to the front.** The service is
 * configured for window-state changes only and cannot retrieve window
 * content, so it never sees what is on screen or typed. That narrow claim is
 * also what the Play accessibility declaration states.
 *
 * Two moments step in:
 * - opening a watched app with nothing left, and
 * - running out while inside one. On entry the blocker schedules one check for
 *   the moment the balance would reach zero, rather than polling. Leaving the
 *   app cancels it.
 *
 * The count comes from [BlockStore]: Dart's figure minus usage since. The
 * service keeps no count of its own, so being killed by an OEM battery manager
 * costs the block until Android rebinds it, never a wrong balance.
 */
class AppBlockerService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private var foreground: String? = null
    private val recheck = Runnable { foreground?.let(::check) }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // The keyboard and the notification shade raise their own windows over
        // the app underneath. Treating them as leaving it would cancel the
        // zero-balance check every time someone types a comment.
        if (isOverlay(pkg)) return

        handler.removeCallbacks(recheck)
        foreground = pkg
        check(pkg)
    }

    private fun check(pkg: String) {
        val store = BlockStore(this)
        // Our own windows (the page itself, the app) never end a pass: the
        // relaunch after "Continue anyway" goes through the page closing.
        if (pkg == packageName) {
            foreground = null
            return
        }
        if (store.passPackage != null && store.passPackage != pkg) {
            store.passPackage = null
        }
        if (!store.enabled || pkg !in store.packages || store.passPackage == pkg) {
            foreground = null
            return
        }

        val remaining = store.remainingSeconds(UsageReader(this), System.currentTimeMillis())
        if (remaining <= 0) {
            block(store, pkg)
        } else {
            // A second past the expected zero, so the usage record has caught
            // up by the time it is read. If it has not, the check simply
            // reschedules for the few seconds left.
            handler.postDelayed(recheck, remaining * 1000 + 1000)
        }
    }

    private fun block(store: BlockStore, pkg: String) {
        foreground = null
        // Home first, so Back from the block screen lands on the launcher
        // rather than on the app that was just covered. Not when reminding:
        // the app stays underneath, so continuing returns to where they were.
        if (store.hard) performGlobalAction(GLOBAL_ACTION_HOME)
        startActivity(
            Intent(this, BlockActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION,
                )
                putExtra(BlockActivity.EXTRA_STALE, store.isStale)
                putExtra(BlockActivity.EXTRA_PACKAGE, pkg)
            },
        )
    }

    private fun isOverlay(pkg: String): Boolean {
        if (pkg == "com.android.systemui") return true
        val keyboards = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            ?: return false
        return keyboards.enabledInputMethodList.any { it.packageName == pkg }
    }

    override fun onInterrupt() {
        handler.removeCallbacks(recheck)
    }

    override fun onDestroy() {
        handler.removeCallbacks(recheck)
        super.onDestroy()
    }

    companion object {
        /**
         * Whether the user has switched the service on in system settings.
         *
         * Read from the secure setting rather than AccessibilityManager: the
         * manager only lists services that are currently bound, and a service
         * the OS has not rebound yet after an update is still switched on.
         */
        fun isOn(context: Context): Boolean {
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            val me = ComponentName(context, AppBlockerService::class.java)
            return enabled.split(':').any {
                ComponentName.unflattenFromString(it) == me
            }
        }

        fun openSettings(context: Context) {
            context.startActivity(
                Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }
}
