package com.jelena.tally

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

                else -> result.notImplemented()
            }
        }
    }
}
