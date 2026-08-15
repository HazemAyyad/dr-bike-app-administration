package com.application.doctorbike

import android.util.Log
import io.flutter.app.FlutterApplication
import com.thingclips.smart.home.sdk.ThingHomeSdk

class DoctorBikeApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        val appKey = metadataValue("THING_SMART_APPKEY")
        val appSecret = metadataValue("THING_SMART_SECRET")
        if (appKey.isNotBlank() && appSecret.isNotBlank()) {
            runCatching {
                ThingHomeSdk.init(this, appKey, appSecret)
                tuyaInitialized = true
                tuyaInitializationMessage = "Tuya SDK initialized"
            }.onFailure { error ->
                tuyaInitialized = false
                tuyaInitializationMessage = error.message ?: "Tuya SDK initialization failed"
                Log.e(TAG, "Tuya SDK initialization failed. Check AppKey, AppSecret, package name, SHA-256, and security AAR.", error)
            }
        } else {
            tuyaInitialized = false
            tuyaInitializationMessage = "Tuya AppKey/AppSecret are missing"
            Log.w(TAG, "Tuya SDK skipped because AppKey/AppSecret are missing.")
        }
    }

    private fun metadataValue(name: String): String {
        return runCatching {
            packageManager
                .getApplicationInfo(packageName, android.content.pm.PackageManager.GET_META_DATA)
                .metaData
                ?.getString(name)
                .orEmpty()
        }.getOrDefault("")
    }

    companion object {
        const val TAG = "DoctorBikeTuya"
        @JvmStatic var tuyaInitialized: Boolean = false
        @JvmStatic var tuyaInitializationMessage: String = "Not initialized"
    }
}