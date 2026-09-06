package com.rastovic.lockin

import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/** Feeds the widget's task list. */
class TodayWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TodayRowFactory(applicationContext)
}

private class TodayRowFactory(
    private val context: android.content.Context,
) : RemoteViewsService.RemoteViewsFactory {

    private var rows: List<TodayWidgetStore.Row> = emptyList()

    override fun onCreate() = Unit

    /**
     * Re-read on every data-changed notification.
     *
     * Held in a field rather than read per row: [getViewAt] is called once per
     * visible row and re-parsing the JSON each time would parse the whole plan
     * for every line of it.
     */
    override fun onDataSetChanged() {
        rows = TodayWidgetStore(context).rows
    }

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun getCount() = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_task_row)
        val row = rows.getOrNull(position) ?: return views

        views.setTextViewText(R.id.row_title, row.title)
        views.setTextViewText(R.id.row_glyph, row.glyph)
        views.setTextViewText(R.id.row_mark, if (row.done) "●" else "○")

        // Done rows dim rather than vanish. The day's shape is the point, and
        // a list that empties as you work tells you nothing about it.
        views.setInt(
            R.id.row_title,
            "setTextColor",
            context.getColor(
                if (row.done) R.color.widget_ink_faint else R.color.widget_ink,
            ),
        )

        // Filled by the template on the parent list. Empty because the whole
        // widget opens the same screen; without it the rows are not clickable
        // at all and the widget feels dead.
        views.setOnClickFillInIntent(R.id.row_root, Intent())
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount() = 1

    override fun getItemId(position: Int) = position.toLong()

    override fun hasStableIds() = false
}
