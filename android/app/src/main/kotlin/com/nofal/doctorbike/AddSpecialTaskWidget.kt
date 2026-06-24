package com.nofal.doctorbike

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class AddSpecialTaskWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.add_special_task_widget).apply {
                val title = widgetData.getString(
                    "special_task_widget_title",
                    context.getString(R.string.widget_add_special_task_label),
                )
                setTextViewText(R.id.widget_title, title)

                val subtitle = widgetData.getString(
                    "special_task_widget_subtitle",
                    context.getString(R.string.widget_add_special_task_subtitle),
                )
                setTextViewText(R.id.widget_subtitle, subtitle)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("doctorbike://add_special_task?homeWidget=true"),
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
