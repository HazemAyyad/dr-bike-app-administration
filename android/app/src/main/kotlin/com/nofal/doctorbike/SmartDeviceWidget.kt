package com.application.doctorbike

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.os.Build
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.util.Log
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
import java.util.UUID

class SmartDeviceWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        Log.d(TAG, "onUpdate widgetIds=${appWidgetIds.joinToString()}")
        appWidgetIds.forEach { widgetId ->
            if (readWidgetData(context, widgetId) == null) {
                configurePendingWidget(context, widgetId, updateNow = false)
            }
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_TOGGLE_SWITCH) return

        val index = intent.getIntExtra(EXTRA_SWITCH_INDEX, -1)
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        val data = readWidgetData(context, widgetId) ?: legacyWidgetData(context) ?: return
        Log.d(
            TAG,
            "toggle widgetId=$widgetId deviceId=${data.optInt(KEY_DEVICE_ID)} index=$index",
        )
        val tuyaDeviceId = data.optString(KEY_TUYA_DEVICE_ID)
        val switches = data.optJSONArray(KEY_SWITCHES) ?: JSONArray()
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

        data.put(KEY_STATUS, "جاري التنفيذ...")
        saveWidgetData(context, widgetId, data)
        refreshWidget(context, widgetId)

        val countryCode = data.optString(KEY_TUYA_COUNTRY_CODE)
        val uid = data.optString(KEY_TUYA_UID)
        val password = data.optString(KEY_TUYA_PASSWORD)
        if (countryCode.isBlank() || uid.isBlank() || password.isBlank()) {
            publishToggle(
                context,
                tuyaDeviceId,
                payload.toString(),
                nextValue,
                switches,
                if (toggleAll) null else index,
                widgetId,
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
                        widgetId,
                        pendingResult::finish,
                    )
                }

                override fun onError(code: String?, error: String?) {
                    data.put(KEY_STATUS, "تعذر تسجيل Tuya")
                    saveWidgetData(context, widgetId, data)
                    refreshWidget(context, widgetId)
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
        widgetId: Int,
        onDone: () -> Unit,
    ) {
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
                    val data = readWidgetData(context, widgetId) ?: JSONObject()
                    data.put(KEY_SWITCHES, switches)
                    data.put(KEY_STATUS, "متصل")
                    saveWidgetData(context, widgetId, data)
                    refreshWidget(context, widgetId)
                    onDone()
                }

                override fun onError(code: String?, error: String?) {
                    val data = readWidgetData(context, widgetId) ?: JSONObject()
                    data.put(KEY_STATUS, "تعذر التنفيذ")
                    saveWidgetData(context, widgetId, data)
                    refreshWidget(context, widgetId)
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
        val data = readWidgetData(context, widgetId) ?: legacyWidgetData(context)
        Log.d(
            TAG,
            "render widgetId=$widgetId source=${if (readWidgetData(context, widgetId) != null) "instance" else "legacy"} " +
                "deviceId=${data?.optInt(KEY_DEVICE_ID)} name=${data?.optString(KEY_NAME)}",
        )
        val name = data?.optString(KEY_NAME)?.takeIf { it.isNotBlank() } ?: "جهاز ذكي"
        val room = data?.optString(KEY_ROOM).orEmpty()
        val status = data?.optString(KEY_STATUS)?.takeIf { it.isNotBlank() } ?: "غير معروف"
        val deviceId = data?.optInt(KEY_DEVICE_ID) ?: 0
        val switches = data?.optJSONArray(KEY_SWITCHES) ?: JSONArray()
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
                    toggleIntent(context, widgetId, ALL_SWITCHES_INDEX),
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
                    setOnClickPendingIntent(viewId, toggleIntent(context, widgetId, index))
                }
            }
        }
        manager.updateAppWidget(widgetId, views)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = widgetPreferences(context).edit()
        appWidgetIds.forEach { editor.remove(widgetKey(it)) }
        editor.apply()
        super.onDeleted(context, appWidgetIds)
    }

    private fun toggleIntent(context: Context, widgetId: Int, index: Int): PendingIntent {
        val intent = Intent(context, SmartDeviceWidget::class.java).apply {
            action = ACTION_TOGGLE_SWITCH
            data = Uri.parse("doctorbike://smart_device/$widgetId/toggle/$index")
            putExtra(EXTRA_SWITCH_INDEX, index)
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            widgetId * 10 + index + 2,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun refreshWidget(context: Context, widgetId: Int) {
        val manager = AppWidgetManager.getInstance(context)
        updateWidget(context, manager, widgetId)
    }

    private fun readSwitches(raw: String?): JSONArray = try {
        JSONArray(raw ?: "[]")
    } catch (_: Exception) {
        JSONArray()
    }

    companion object {
        private const val TAG = "SmartDeviceWidgetFlow"
        private const val ACTION_TOGGLE_SWITCH =
            "com.application.doctorbike.SMART_DEVICE_WIDGET_TOGGLE"
        private const val EXTRA_SWITCH_INDEX = "switch_index"
        private const val ALL_SWITCHES_INDEX = -2
        private const val WIDGET_PREFS = "smart_device_widget_instances"
        private const val PENDING_PREFS = "smart_device_widget_pending"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_NAME = "name"
        private const val KEY_ROOM = "room"
        private const val KEY_STATUS = "status"
        private const val KEY_TUYA_DEVICE_ID = "tuya_device_id"
        private const val KEY_TUYA_COUNTRY_CODE = "tuya_country_code"
        private const val KEY_TUYA_UID = "tuya_uid"
        private const val KEY_TUYA_PASSWORD = "tuya_password"
        private const val KEY_SWITCHES = "switches"

        fun requestPin(context: Context, config: String): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || config.isBlank()) return false
            try {
                JSONObject(config)
            } catch (_: Exception) {
                return false
            }
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            val token = UUID.randomUUID().toString()
            val provider = ComponentName(context, SmartDeviceWidget::class.java)
            val knownWidgetIds = manager.getAppWidgetIds(provider)
            val pendingRecord = JSONObject().apply {
                put("config", JSONObject(config))
                put("known_widget_ids", JSONArray(knownWidgetIds.toList()))
            }
            pendingPreferences(context).edit()
                .clear()
                .putString(token, pendingRecord.toString())
                .apply()
            val device = JSONObject(config)
            Log.d(
                TAG,
                "requestPin token=$token deviceId=${device.optInt(KEY_DEVICE_ID)} " +
                    "name=${device.optString(KEY_NAME)} knownWidgetIds=${knownWidgetIds.joinToString()}",
            )
            val requested = manager.requestPinAppWidget(provider, null, null)
            Log.d(TAG, "requestPin result=$requested token=$token")
            if (!requested) pendingPreferences(context).edit().remove(token).apply()
            return requested
        }

        fun configurePendingWidget(
            context: Context,
            widgetId: Int,
            updateNow: Boolean = true,
        ): Boolean {
            if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return false
            val preferences = pendingPreferences(context)
            val entry = preferences.all.entries.firstOrNull()
            if (entry == null) {
                Log.e(TAG, "configure widgetId=$widgetId failed: no pending config")
                return false
            }
            val pendingRaw = entry.value as? String
            if (pendingRaw == null) {
                Log.e(TAG, "configure widgetId=$widgetId failed: pending config is not text")
                return false
            }
            val pendingRecord = try {
                JSONObject(pendingRaw)
            } catch (_: Exception) {
                Log.e(TAG, "configure widgetId=$widgetId failed: invalid pending data")
                return false
            }
            val knownWidgetIds = pendingRecord.optJSONArray("known_widget_ids") ?: JSONArray()
            if ((0 until knownWidgetIds.length()).any { knownWidgetIds.optInt(it) == widgetId }) {
                Log.d(TAG, "configure widgetId=$widgetId skipped: widget existed before request")
                return false
            }
            val device = pendingRecord.optJSONObject("config")
            if (device == null) {
                Log.e(TAG, "configure widgetId=$widgetId failed: config missing")
                return false
            }
            val config = device.toString()
            Log.d(
                TAG,
                "configure widgetId=$widgetId deviceId=${device.optInt(KEY_DEVICE_ID)} " +
                    "name=${device.optString(KEY_NAME)} token=${entry.key}",
            )
            widgetPreferences(context).edit()
                .putString(widgetKey(widgetId), config)
                .apply()
            preferences.edit().remove(entry.key).apply()
            if (updateNow) {
                SmartDeviceWidget().updateWidget(
                    context,
                    AppWidgetManager.getInstance(context),
                    widgetId,
                )
            }
            return true
        }

        private fun widgetPreferences(context: Context) =
            context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)

        private fun pendingPreferences(context: Context) =
            context.getSharedPreferences(PENDING_PREFS, Context.MODE_PRIVATE)

        private fun widgetKey(widgetId: Int) = "widget_$widgetId"

        private fun readWidgetData(context: Context, widgetId: Int): JSONObject? {
            if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return null
            val raw = widgetPreferences(context).getString(widgetKey(widgetId), null) ?: return null
            return try {
                JSONObject(raw)
            } catch (_: Exception) {
                null
            }
        }

        private fun saveWidgetData(context: Context, widgetId: Int, data: JSONObject) {
            if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
            widgetPreferences(context).edit().putString(widgetKey(widgetId), data.toString()).apply()
        }

        private fun legacyWidgetData(context: Context): JSONObject? {
            val data = HomeWidgetPlugin.getData(context)
            val legacyDeviceId = data.getInt("smart_device_widget_id", 0)
            if (legacyDeviceId == 0) return null
            return JSONObject().apply {
                put(KEY_DEVICE_ID, legacyDeviceId)
                put(KEY_NAME, data.getString("smart_device_widget_name", null).orEmpty())
                put(KEY_ROOM, data.getString("smart_device_widget_room", null).orEmpty())
                put(KEY_STATUS, data.getString("smart_device_widget_status", null).orEmpty())
                put(KEY_TUYA_DEVICE_ID, data.getString("smart_device_widget_tuya_id", null).orEmpty())
                put(KEY_TUYA_COUNTRY_CODE, data.getString("smart_device_widget_tuya_country_code", null).orEmpty())
                put(KEY_TUYA_UID, data.getString("smart_device_widget_tuya_uid", null).orEmpty())
                put(KEY_TUYA_PASSWORD, data.getString("smart_device_widget_tuya_password", null).orEmpty())
                val legacySwitches = try {
                    JSONArray(data.getString("smart_device_widget_switches", null) ?: "[]")
                } catch (_: Exception) {
                    JSONArray()
                }
                put(KEY_SWITCHES, legacySwitches)
            }
        }
    }
}
