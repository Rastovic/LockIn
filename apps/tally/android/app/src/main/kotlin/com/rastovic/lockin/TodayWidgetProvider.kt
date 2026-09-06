package com.rastovic.lockin

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

    /**
     * Redraws on the events that can invalidate the widget without the app
     * running: the date rolling over, a clock or timezone change, and boot.
     *
     * **These cost nothing.** They are broadcasts Android already sends and
     * the widget only redraws from values it already has, so the alternative -
     * polling on a short `updatePeriodMillis` - would spend battery to learn
     * the same thing later.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            -> TodayWidgetStore.refresh(context)
        }
    }

    companion object {

        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val store = TodayWidgetStore(context)

            // Past the day boundary with nothing new written, which happens
            // whenever the app has not been opened since. Yesterday's list is
            // hidden rather than relabelled: a widget that is confidently
            // wrong is worse than one that admits it needs opening.
            val stale = store.isStale

            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.widget_today)

                views.setTextViewText(
                    R.id.widget_date,
                    if (stale) {
                        context.getString(R.string.widget_title)
                    } else {
                        store.dateLabel.ifEmpty {
                            context.getString(R.string.widget_title)
                        }
                    },
                )

                // The count is the whole summary: a glance says whether the
                // day is started, half done, or finished.
                views.setTextViewText(
                    R.id.widget_count,
                    when {
                        stale || !store.hasData -> ""
                        store.totalCount == 0 -> ""
                        else -> "${store.doneCount}/${store.totalCount}"
                    },
                )

                // Nothing about minutes until usage access exists. A confident
                // zero would be a claim the app cannot make yet.
                if (store.usageVisible && !stale) {
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
                views.setTextViewText(
                    R.id.widget_empty,
                    context.getString(
                        if (stale) R.string.widget_new_day else R.string.widget_empty,
                    ),
                )
                // The adapter still holds yesterday's rows until the app runs
                // again, so the list is hidden outright rather than trusted to
                // be empty.
                views.setViewVisibility(
                    R.id.widget_list,
                    if (stale) View.GONE else View.VISIBLE,
                )
                views.setViewVisibility(
                    R.id.widget_empty,
                    if (stale) View.VISIBLE else View.GONE,
                )

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
