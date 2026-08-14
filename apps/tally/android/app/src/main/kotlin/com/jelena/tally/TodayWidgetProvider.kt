package com.jelena.tally

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews

/**
 * Today's plan on the home screen.
 *
 * **Read only, deliberately.** Tapping opens the app rather than ticking
 * anything: ticking from a widget means either a second writer to the ledger
 * living in Kotlin, or a background isolate opening the same SQLite file as
 * the running app. One duplicates the rules this whole app is built on, the
 * other risks the data. Neither is worth saving a tap on a list you are about
 * to open anyway.
 */
class TodayWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
        render(context, manager, ids)
    }

    companion object {

        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val store = TodayWidgetStore(context)

            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.widget_today)

                views.setTextViewText(
                    R.id.widget_date,
                    store.dateLabel.ifEmpty { context.getString(R.string.widget_title) },
                )

                // The count is the whole summary: a glance says whether the
                // day is started, half done, or finished.
                views.setTextViewText(
                    R.id.widget_count,
                    when {
                        !store.hasData -> ""
                        store.totalCount == 0 -> ""
                        else -> "${store.doneCount}/${store.totalCount}"
                    },
                )

                // Nothing about minutes until usage access exists. A confident
                // zero would be a claim the app cannot make yet.
                if (store.usageVisible) {
                    views.setViewVisibility(R.id.widget_balance, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_balance,
                        formatMinutes(store.spendableSeconds),
                    )
                } else {
                    views.setViewVisibility(R.id.widget_balance, View.GONE)
                }

                views.setRemoteAdapter(
                    R.id.widget_list,
                    Intent(context, TodayWidgetService::class.java).apply {
                        // A unique data uri per widget id, or Android reuses
                        // one adapter across every placed instance and they
                        // all show whatever the last one asked for.
                        data = Uri.parse("tally://widget/$id")
                    },
                )
                views.setEmptyView(R.id.widget_list, R.id.widget_empty)

                val open = PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    },
                    PendingIntent.FLAG_IMMUTABLE or
                        PendingIntent.FLAG_UPDATE_CURRENT,
                )
                views.setOnClickPendingIntent(R.id.widget_root, open)
                // Rows need a template rather than their own intents: a
                // collection view fills in per-item extras, and a plain click
                // listener set inside the adapter is ignored.
                views.setPendingIntentTemplate(R.id.widget_list, open)

                manager.updateAppWidget(id, views)
            }
        }

        /** Whole minutes, floored, with a real minus sign. Mirrors Dart. */
        private fun formatMinutes(seconds: Int): String {
            val minutes = Math.floorDiv(seconds, 60)
            return if (minutes < 0) "−${-minutes} min" else "$minutes min"
        }
    }
}
