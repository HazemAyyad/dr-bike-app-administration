package com.nofal.doctorbike

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class EmployeeWifiPresenceService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private var running = false
    private var apiBaseUrl: String = ""
    private var token: String = ""

    private val tick = object : Runnable {
        override fun run() {
            sendPresence()
            if (running) {
                handler.postDelayed(this, INTERVAL_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val incomingBaseUrl = intent?.getStringExtra(EXTRA_BASE_URL)
        val incomingToken = intent?.getStringExtra(EXTRA_TOKEN)
        if (!incomingBaseUrl.isNullOrBlank() && !incomingToken.isNullOrBlank()) {
            apiBaseUrl = incomingBaseUrl
            token = incomingToken
            prefs.edit()
                .putString(EXTRA_BASE_URL, apiBaseUrl)
                .putString(EXTRA_TOKEN, token)
                .apply()
        } else {
            apiBaseUrl = prefs.getString(EXTRA_BASE_URL, "") ?: ""
            token = prefs.getString(EXTRA_TOKEN, "") ?: ""
        }

        if (apiBaseUrl.isBlank() || token.isBlank()) {
            stopSelf()
            return START_NOT_STICKY
        }

        startForeground(NOTIFICATION_ID, notification())
        if (!running) {
            running = true
            handler.removeCallbacks(tick)
            handler.post(tick)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        running = false
        handler.removeCallbacks(tick)
        executor.shutdownNow()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun sendPresence() {
        val base = apiBaseUrl.trimEnd('/')
        if (base.isBlank() || token.isBlank()) return

        val status = readNetworkStatus()
        executor.execute {
            try {
                val url = URL("$base/employee/wifi-presence")
                val connection = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 15000
                    readTimeout = 15000
                    doOutput = true
                    setRequestProperty("Accept", "application/json")
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $token")
                }
                val body = JSONObject().apply {
                    put("connected", status.ssid != null)
                    put("network_connected", status.networkConnected)
                    status.ssid?.let { put("ssid", it) }
                }
                OutputStreamWriter(connection.outputStream).use { writer ->
                    writer.write(body.toString())
                    writer.flush()
                }
                val code = connection.responseCode
                connection.disconnect()
                Log.d(TAG, "presence sent code=$code ssid=${status.ssid}")
            } catch (e: Exception) {
                Log.d(TAG, "presence send failed: ${e.message}")
            }
        }
    }

    private fun readNetworkStatus(): WifiPresenceStatus {
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork
        val caps = connectivityManager.getNetworkCapabilities(network)
        val hasNetwork = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        val isWifi = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true

        if (!isWifi) {
            return WifiPresenceStatus(networkConnected = hasNetwork, ssid = null)
        }

        val wifiManager =
            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val raw = wifiManager.connectionInfo?.ssid
        return WifiPresenceStatus(
            networkConnected = hasNetwork,
            ssid = normalizeSsid(raw),
        )
    }

    private fun normalizeSsid(raw: String?): String? {
        var ssid = raw?.trim()
        if (ssid.isNullOrBlank() || ssid == "<unknown ssid>") return null
        if ((ssid.startsWith("\"") && ssid.endsWith("\"")) ||
            (ssid.startsWith("'") && ssid.endsWith("'"))) {
            ssid = ssid.substring(1, ssid.length - 1).trim()
        }
        return ssid.ifBlank { null }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Employee network presence",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps employee network status updated"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun notification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Doctor Bike")
            .setContentText("تحديث حالة شبكة الموظف")
            .setOngoing(true)
            .setShowWhen(false)
            .build()
    }

    private data class WifiPresenceStatus(
        val networkConnected: Boolean,
        val ssid: String?,
    )

    companion object {
        private const val TAG = "DrBikeWifiPresence"
        private const val PREFS = "employee_wifi_presence"
        private const val CHANNEL_ID = "employee_wifi_presence"
        private const val NOTIFICATION_ID = 2409
        private const val INTERVAL_MS = 45_000L
        private const val EXTRA_BASE_URL = "base_url"
        private const val EXTRA_TOKEN = "token"
        private const val ACTION_STOP = "com.nofal.doctorbike.STOP_WIFI_PRESENCE"

        fun start(context: Context, baseUrl: String, token: String) {
            val intent = Intent(context, EmployeeWifiPresenceService::class.java).apply {
                putExtra(EXTRA_BASE_URL, baseUrl)
                putExtra(EXTRA_TOKEN, token)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, EmployeeWifiPresenceService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }
}
