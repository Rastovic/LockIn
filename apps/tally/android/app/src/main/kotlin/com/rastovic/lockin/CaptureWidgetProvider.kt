package com.rastovic.lockin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** A capture box on the home screen, one tap from anywhere. */
class CaptureWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) = render(context, manager, ids)

    companion object {

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, CaptureWidgetProvider::class.java),
            )
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val waiting = CaptureQueue(context).count
            val palette = WidgetTheme(context).palette()

            for (id in ids) {
                val views =
                    RemoteViews(context.packageName, R.layout.widget_capture)

                views.setInt(R.id.capture_bg, "setColorFilter", palette.bg)
                views.setInt(
                    R.id.capture_bg,
                    "setImageAlpha",
                    WidgetTheme.CARD_ALPHA,
                )
                views.setTextColor(R.id.capture_plus, palette.solvent)
                views.setTextColor(R.id.capture_waiting, palette.inkMuted)

                // The count is the reassurance. A captured line lives outside
                // the app's database until it next runs, and with nothing on
                // screen there would be nothing to say it was kept.
                views.setTextViewText(
                    R.id.capture_waiting,
                    when (waiting) {
                        0 -> context.getString(R.string.capture_prompt)
                        1 -> context.getString(R.string.capture_waiting_one)
                        else -> context.getString(
                            R.string.capture_waiting_many,
                            waiting,
                        )
                    },
                )

                views.setOnClickPendingIntent(
                    R.id.capture_root,
                    PendingIntent.getActivity(
                        context,
                        0,
                        Intent(context, CaptureActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        },
                        PendingIntent.FLAG_IMMUTABLE or
                            PendingIntent.FLAG_UPDATE_CURRENT,
                    ),
                )

                manager.updateAppWidget(id, views)
            }
        }
    }
}
