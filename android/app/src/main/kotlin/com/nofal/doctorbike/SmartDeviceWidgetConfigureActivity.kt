package com.application.doctorbike

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.util.Log

class SmartDeviceWidgetConfigureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        val widgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        Log.d(
            "SmartDeviceWidgetFlow",
            "configure activity opened widgetId=$widgetId extras=${intent?.extras?.keySet()?.joinToString()}",
        )

        if (SmartDeviceWidget.configurePendingWidget(applicationContext, widgetId)) {
            setResult(
                RESULT_OK,
                Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
            )
            Log.d("SmartDeviceWidgetFlow", "configure activity success widgetId=$widgetId")
        } else {
            Log.e("SmartDeviceWidgetFlow", "configure activity cancelled widgetId=$widgetId")
        }
        finish()
    }
}
