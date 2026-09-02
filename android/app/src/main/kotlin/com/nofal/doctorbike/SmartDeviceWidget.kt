package com.application.doctorbike

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.thingclips.smart.android.user.api.ILoginCallback
import com.thingclips.smart.android.user.bean.User
import com.thingclips.smart.home.sdk.ThingHomeSdk
import com.thingclips.smart.sdk.api.IResultCallback
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class SmartDeviceWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_TOGGLE_SWITCH) return

        val index = intent.getIntExtra(EXTRA_SWITCH_INDEX, -1)
        val data = HomeWidgetPlugin.getData(context)
        val tuyaDeviceId = data.getString(KEY_TUYA_DEVICE_ID, null).orEmpty()
        val switches = readSwitches(data.getString(KEY_SWITCHES, null))
        val toggleAll = index == ALL_SWITCHES_INDEX
        if (switches.length() == 0 || tuyaDeviceId.isBlank()) return
        if (!toggleAll && index !in 0 until switches.length()) return

        val selectedItem = if (toggleAll) null else switches.optJSONObject(index)
        if (!toggleAll && selectedItem == null) return
        val anyActive = (0 until switches.length()).any {
            switches.optJSONObject(it)?.optBoolean("active", false) == true
        }
        val nextValue = if (toggleAll) !anyActive else !selectedItem!!.optBoolean("active", false)
        val payload = JSONObject()
        if (toggleAll) {
            for (itemIndex in 0 until switches.length()) {
                val item = switches.optJSONObject(itemIndex) ?: continue
                val dpId = item.optString("dp_id")
                if (dpId.isNotBlank()) payload.put(dpId, nextValue)
            }
        } else {
            val dpId = selectedItem!!.optString("dp_id")
            if (dpId.isBlank()) return
            payload.put(dpId, nextValue)
        }
        if (payload.length() == 0) return
        val pendingResult = goAsync()

        data.edit().putString(KEY_STATUS, "جاري التنفيذ...").apply()
        refreshAll(context)

        val countryCode = data.getString(KEY_TUYA_COUNTRY_CODE, null).orEmpty()
        val uid = data.getString(KEY_TUYA_UID, null).orEmpty()
        val password = data.getString(KEY_TUYA_PASSWORD, null).orEmpty()
        if (countryCode.isBlank() || uid.isBlank() || password.isBlank()) {
            publishToggle(
                context,
                tuyaDeviceId,
                payload.toString(),
                nextValue,
                switches,
                if (toggleAll) null else index,
                pendingResult::finish,
            )
            return
        }

        ThingHomeSdk.getUserInstance().loginOrRegisterWithUid(
            countryCode,
            uid,
            password,
            object : ILoginCallback {
                override fun onSuccess(user: User) {
                    publishToggle(
                        context,
                        tuyaDeviceId,
                        payload.toString(),
                        nextValue,
                        switches,
                        if (toggleAll) null else index,
                        pendingResult::finish,
                    )
                }

                override fun onError(code: String?, error: String?) {
                    data.edit().putString(KEY_STATUS, "تعذر تسجيل Tuya").apply()
                    refreshAll(context)
                    pendingResult.finish()
                }
            },
        )
    }

    private fun publishToggle(
        context: Context,
        tuyaDeviceId: String,
        payload: String,
        nextValue: Boolean,
        switches: JSONArray,
        switchIndex: Int?,
        onDone: () -> Unit,
    ) {
        val data = HomeWidgetPlugin.getData(context)
        ThingHomeSdk.newDeviceInstance(tuyaDeviceId).publishDps(
            payload,
            object : IResultCallback {
                override fun onSuccess() {
                    if (switchIndex == null) {
                        for (index in 0 until switches.length()) {
                            switches.optJSONObject(index)?.put("active", nextValue)
                        }
                    } else {
                        switches.optJSONObject(switchIndex)?.put("active", nextValue)
                    }
                    data.edit()
                        .putString(KEY_SWITCHES, switches.toString())
                        .putString(KEY_STATUS, "متصل")
                        .apply()
                    refreshAll(context)
                    onDone()
                }

                override fun onError(code: String?, error: String?) {
                    data.edit().putString(KEY_STATUS, "تعذر التنفيذ").apply()
                    refreshAll(context)
                    onDone()
                }
            },
        )
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val name = data.getString(KEY_NAME, null) ?: "جهاز ذكي"
        val room = data.getString(KEY_ROOM, null).orEmpty()
        val status = data.getString(KEY_STATUS, null) ?: "غير معروف"
        val deviceId = data.getInt(KEY_DEVICE_ID, 0)
        val switches = readSwitches(data.getString(KEY_SWITCHES, null))
        val switchViewIds = intArrayOf(
            R.id.smart_device_widget_switch_1,
            R.id.smart_device_widget_switch_2,
            R.id.smart_device_widget_switch_3,
            R.id.smart_device_widget_switch_4,
        )

        val views = RemoteViews(context.packageName, R.layout.smart_device_widget).apply {
            setTextViewText(R.id.smart_device_widget_name, name)
            setTextViewText(
                R.id.smart_device_widget_subtitle,
                listOf(room, status).filter { it.isNotBlank() }.joinToString(" • "),
            )
            val openIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("doctorbike://smart_device?id=$deviceId&homeWidget=true"),
            )
            setOnClickPendingIntent(R.id.smart_device_widget_container, openIntent)
            if (switches.length() > 0) {
                setOnClickPendingIntent(
                    R.id.smart_device_widget_power,
                    toggleIntent(context, ALL_SWITCHES_INDEX),
                )
            }

            switchViewIds.forEachIndexed { index, viewId ->
                val item = switches.optJSONObject(index)
                if (item == null) {
                    setViewVisibility(viewId, View.INVISIBLE)
                } else {
                    val active = item.optBoolean("active", false)
                    setViewVisibility(viewId, View.VISIBLE)
                    setTextViewText(viewId, item.optString("label", "مفتاح ${index + 1}"))
                    setTextColor(viewId, Color.parseColor(if (active) "#148B69" else "#5E6878"))
                    setInt(
                        viewId,
                        "setBackgroundResource",
                        if (active) R.drawable.widget_smart_switch_on else R.drawable.widget_smart_switch_off,
                    )
                    setOnClickPendingIntent(viewId, toggleIntent(context, index))
                }
            }
        }
        manager.updateAppWidget(widgetId, views)
    }

    private fun toggleIntent(context: Context, index: Int): PendingIntent {
        val intent = Intent(context, SmartDeviceWidget::class.java).apply {
            action = ACTION_TOGGLE_SWITCH
            data = Uri.parse("doctorbike://smart_device/toggle/$index")
            putExtra(EXTRA_SWITCH_INDEX, index)
        }
        return PendingIntent.getBroadcast(
            context,
            4100 + index,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, SmartDeviceWidget::class.java)
        manager.getAppWidgetIds(component).forEach { updateWidget(context, manager, it) }
    }

    private fun readSwitches(raw: String?): JSONArray = try {
        JSONArray(raw ?: "[]")
    } catch (_: Exception) {
        JSONArray()
    }

    companion object {
        private const val ACTION_TOGGLE_SWITCH =
            "com.application.doctorbike.SMART_DEVICE_WIDGET_TOGGLE"
        private const val EXTRA_SWITCH_INDEX = "switch_index"
        private const val ALL_SWITCHES_INDEX = -2
        private const val KEY_DEVICE_ID = "smart_device_widget_id"
        private const val KEY_NAME = "smart_device_widget_name"
        private const val KEY_ROOM = "smart_device_widget_room"
        private const val KEY_STATUS = "smart_device_widget_status"
        private const val KEY_TUYA_DEVICE_ID = "smart_device_widget_tuya_id"
        private const val KEY_TUYA_COUNTRY_CODE =
            "smart_device_widget_tuya_country_code"
        private const val KEY_TUYA_UID = "smart_device_widget_tuya_uid"
        private const val KEY_TUYA_PASSWORD = "smart_device_widget_tuya_password"
        private const val KEY_SWITCHES = "smart_device_widget_switches"
    }
}
