package com.application.doctorbike

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class SmartDeviceWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val name = data.getString("smart_device_widget_name", null) ?: "جهاز ذكي"
        val room = data.getString("smart_device_widget_room", null).orEmpty()
        val status = data.getString("smart_device_widget_status", null) ?: "افتح التطبيق للتحديث"
        val deviceId = data.getInt("smart_device_widget_id", 0)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.smart_device_widget).apply {
                setTextViewText(R.id.smart_device_widget_name, name)
                setTextViewText(R.id.smart_device_widget_subtitle, listOf(room, status).filter { it.isNotBlank() }.joinToString(" • "))
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("doctorbike://smart_device?id=$deviceId&homeWidget=true"),
                )
                setOnClickPendingIntent(R.id.smart_device_widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
