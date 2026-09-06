package com.rastovic.lockin

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The one place Android talks to Dart.
 *
 * Kept thin on purpose: [UsageReader] holds the logic, this holds the wiring.
 * Everything crossing the channel is a plain map, so the Dart side owns its own
 * types and neither side has to know the other's.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "tally/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        retireCountingNotice()

        val reader = UsageReader(applicationContext)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAccess" -> result.success(reader.hasAccess())

                "openAccessSettings" -> {
                    reader.openAccessSettings()
                    result.success(null)
                }

                "spans" -> {
                    val from = call.argument<Long>("from")
                    val to = call.argument<Long>("to")
                    val packages = call.argument<List<String>>("packages")
                    if (from == null || to == null || packages == null) {
                        result.error("bad_args", "from, to and packages are required", null)
                        return@setMethodCallHandler
                    }
                    // A refused permission is an ordinary state, not a failure:
                    // the app stays usable and only the spending side is dark.
                    if (!reader.hasAccess()) {
                        result.success(emptyList<Map<String, Any>>())
                        return@setMethodCallHandler
                    }
                    result.success(
                        reader.spans(from, to, packages.toSet()).map {
                            mapOf(
                                "packageName" to it.packageName,
                                "start" to it.start,
                                "end" to it.end,
                            )
                        },
                    )
                }

                "installedApps" -> {
                    if (!reader.hasAccess()) {
                        result.success(emptyList<Map<String, Any>>())
                        return@setMethodCallHandler
                    }
                    val days = call.argument<Int>("recentDays") ?: 7
                    result.success(
                        reader.installedApps(days, System.currentTimeMillis()),
                    )
                }

                // Dart writes finished strings; nothing here knows what a
                // sticker id means or how a day is assembled. See
                // TodayWidgetStore.
                "updateTodayWidget" -> {
                    TodayWidgetStore(applicationContext).write(
                        dateLabel = call.argument<String>("dateLabel") ?: "",
                        rowsJson = call.argument<String>("rows") ?: "[]",
                        done = call.argument<Int>("doneCount") ?: 0,
                        total = call.argument<Int>("totalCount") ?: 0,
                        spendable = call.argument<Int>("spendableSeconds") ?: 0,
                        usageVisible =
                            call.argument<Boolean>("usageVisible") ?: false,
                        validUntil =
                            call.argument<Long>("validUntilMillis") ?: 0L,
                    )
                    TodayWidgetStore.refresh(applicationContext)
                    result.success(null)
                }

                // Everything captured from the home screen since the app was
                // last open. Read and cleared together, so nothing typed
                // during the drain can fall between the two.
                "drainCaptures" -> {
                    result.success(CaptureQueue(applicationContext).drain())
                    CaptureWidgetProvider.refresh(applicationContext)
                }

                // The running block, counting down in the shade and - on
                // Android 16, if the system agrees - in the status bar chip.
                "showFocusNotice" -> {
                    val endsAt = call.argument<Long>("endsAtMillis")
                    if (endsAt == null) {
                        result.error("bad_args", "endsAtMillis is required", null)
                        return@setMethodCallHandler
                    }
                    FocusNotice.show(
                        applicationContext,
                        endsAtMillis = endsAt,
                        remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0,
                        totalSeconds = call.argument<Int>("totalSeconds") ?: 0,
                        taskTitle = call.argument<String>("taskTitle"),
                        paused = call.argument<Boolean>("paused") ?: false,
                    )
                    result.success(null)
                }

                "hideFocusNotice" -> {
                    FocusNotice.hide(applicationContext)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Clears what the removed balance notice left behind.
     *
     * The live "x min left" notice is gone, and with it the foreground service
     * that had to post one. Two things outlive the code that made them: any
     * notification still on screen from a service killed mid-update, and the
     * channel, because **an installed app keeps every channel it ever
     * created**. Without this the user is left with a "Counting" switch in
     * system settings that controls nothing.
     */
    private fun retireCountingNotice() {
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(RETIRED_ONGOING_ID)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.deleteNotificationChannel(RETIRED_CHANNEL_ONGOING)
        }
    }

    private companion object {
        /** The ongoing balance notice, removed. Ids outlive their features. */
        const val RETIRED_ONGOING_ID = 1001
        const val RETIRED_CHANNEL_ONGOING = "tally.counting"
    }
}
