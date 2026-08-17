package com.application.doctorbike

import android.app.KeyguardManager
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.thingclips.smart.android.ble.api.BleScanResponse
import com.thingclips.smart.android.ble.api.LeScanSetting
import com.thingclips.smart.android.ble.api.ScanDeviceBean
import com.thingclips.smart.android.ble.api.ScanType
import com.thingclips.smart.sdk.api.IBleActivatorListener
import com.thingclips.smart.sdk.api.IMultiModeActivatorListener
import com.thingclips.smart.sdk.bean.BleActivatorBean
import com.thingclips.smart.sdk.bean.MultiModeActivatorBean
import android.provider.Settings
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.lifecycle.Lifecycle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.thingclips.smart.android.user.api.ILoginCallback
import com.thingclips.smart.android.user.bean.User
import com.thingclips.smart.home.sdk.ThingHomeSdk
import com.thingclips.smart.home.sdk.bean.HomeBean
import com.thingclips.smart.home.sdk.builder.ActivatorBuilder
import com.thingclips.smart.home.sdk.callback.IThingHomeResultCallback
import com.thingclips.smart.sdk.api.IThingActivator
import com.thingclips.smart.sdk.api.IThingActivatorGetToken
import com.thingclips.smart.sdk.api.IThingSmartActivatorListener
import com.thingclips.smart.sdk.api.IResultCallback
import com.thingclips.smart.sdk.bean.DeviceBean
import com.thingclips.smart.sdk.enums.ActivatorModelEnum
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONObject

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "dr_bike/biometric"
    private val wifiPresenceChannelName = "dr_bike/employee_wifi_presence"
    private val smartHomeChannelName = "dr_bike/smart_home"
    private val strong = BiometricManager.Authenticators.BIOMETRIC_STRONG
    private val weak = BiometricManager.Authenticators.BIOMETRIC_WEAK
    private val deviceCredential = BiometricManager.Authenticators.DEVICE_CREDENTIAL
    private val strongOrCredential = strong or deviceCredential
    private lateinit var keyguardDirectLauncher: ActivityResultLauncher<Intent>
    private lateinit var biometricProxyLauncher: ActivityResultLauncher<Intent>
    private var pendingKeyguardResult: MethodChannel.Result? = null
    private var keyguardLaunchStartedAt: Long = 0L
    private var activeSmartHomeActivator: IThingActivator? = null
    private val smartHomeHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        keyguardDirectLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { activityResult ->
            Log.d(
                "DrBikeBiometric",
                "Direct Keyguard ActivityResult resultCode=${activityResult.resultCode}"
            )
            handleKeyguardActivityResult(activityResult.resultCode, "keyguardDirect")
        }
        biometricProxyLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { activityResult ->
            Log.d(
                "DrBikeBiometric",
                "ProxyActivity ActivityResult resultCode=${activityResult.resultCode}"
            )
            handleKeyguardActivityResult(activityResult.resultCode, "keyguardProxy")
        }
        Log.d("DrBikeBiometric", "Keyguard direct and proxy ActivityResultLaunchers initialized")
    }

    override fun onResume() {
        super.onResume()
        val pendingForMs = if (keyguardLaunchStartedAt > 0L) {
            System.currentTimeMillis() - keyguardLaunchStartedAt
        } else {
            0L
        }
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        Log.d(
            "DrBikeBiometric",
            "onResume lifecycle=${lifecycle.currentState} hasFocus=${window?.decorView?.hasWindowFocus()} " +
                "pendingKeyguard=${pendingKeyguardResult != null} pendingForMs=$pendingForMs " +
                "isKeyguardLocked=${keyguardManager.isKeyguardLocked}"
        )
    }

    override fun onPause() {
        Log.d(
            "DrBikeBiometric",
            "onPause lifecycle=${lifecycle.currentState} hasFocus=${window?.decorView?.hasWindowFocus()} " +
                "pendingKeyguard=${pendingKeyguardResult != null}"
        )
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(checkAvailability())
                    "authenticate" -> authenticate(result, strong, "strong")
                    "authenticateStrong" -> authenticate(result, strong, "strong")
                    "authenticateWeak" -> authenticate(result, weak, "weak")
                    "authenticateDeviceCredential" -> authenticate(result, deviceCredential, "deviceCredential")
                    "authenticateStrongOrCredential" -> authenticate(result, strongOrCredential, "strongOrCredential")
                    "authenticateKeyguard" -> authenticateKeyguard(result)
                    "authenticateKeyguardDirect" -> authenticateKeyguardDirect(result)
                    "openSecuritySettings" -> openSecuritySettings(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wifiPresenceChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val baseUrl = call.argument<String>("baseUrl") ?: ""
                        val token = call.argument<String>("token") ?: ""
                        if (baseUrl.isBlank() || token.isBlank()) {
                            result.success(false)
                        } else {
                            EmployeeWifiPresenceService.start(applicationContext, baseUrl, token)
                            result.success(true)
                        }
                    }
                    "stop" -> {
                        EmployeeWifiPresenceService.stop(applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smartHomeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(
                        mapOf(
                            "initialized" to DoctorBikeApplication.tuyaInitialized,
                            "platform" to "android",
                            "message" to DoctorBikeApplication.tuyaInitializationMessage,
                        )
                    )
                    "loginWithUid" -> loginTuyaWithUid(call, result)
                    "createHome" -> createTuyaHome(call, result)
                    "startWifiPairing" -> startTuyaWifiPairing(call, result)
                    "scanBluetoothDevices" -> scanTuyaBluetoothDevices(call, result)
                    "startBluetoothPairing" -> startTuyaBluetoothPairing(call, result)
                    "getDeviceStatus" -> getTuyaDeviceStatus(call, result)
                    "renameDevice" -> renameTuyaDevice(call, result)
                    "removeDevice" -> removeTuyaDevice(call, result)
                    "publishDps" -> publishTuyaDps(call, result)
                    "stopPairing" -> {
                        stopSmartHomeActivator()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun loginTuyaWithUid(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(
                mapOf(
                    "success" to false,
                    "uid" to "",
                    "code" to "tuya_not_initialized",
                    "message" to DoctorBikeApplication.tuyaInitializationMessage,
                )
            )
            return
        }

        val countryCode = call.argument<String>("countryCode") ?: ""
        val uid = call.argument<String>("uid") ?: ""
        val password = call.argument<String>("password") ?: ""
        if (countryCode.isBlank() || uid.isBlank() || password.isBlank()) {
            result.success(
                mapOf(
                    "success" to false,
                    "uid" to uid,
                    "code" to "missing_uid_login_arguments",
                    "message" to "Missing Tuya UID login arguments",
                )
            )
            return
        }

        ThingHomeSdk.getUserInstance().loginOrRegisterWithUid(
            countryCode,
            uid,
            password,
            object : ILoginCallback {
                override fun onSuccess(user: User) {
                    result.success(
                        mapOf(
                            "success" to true,
                            "uid" to (user.uid ?: uid),
                            "code" to "",
                            "message" to "Tuya UID login succeeded",
                        )
                    )
                }

                override fun onError(code: String?, error: String?) {
                    result.success(
                        mapOf(
                            "success" to false,
                            "uid" to uid,
                            "code" to safeTuyaErrorCode(code),
                            "message" to safeTuyaErrorMessage(error),
                        )
                    )
                }
            }
        )
    }
    private fun createTuyaHome(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(
                mapOf(
                    "success" to false,
                    "tuya_home_id" to "",
                    "name" to "",
                    "code" to "tuya_not_initialized",
                    "message" to DoctorBikeApplication.tuyaInitializationMessage,
                )
            )
            return
        }

        val name = call.argument<String>("name")?.takeIf { it.isNotBlank() } ?: "Doctor Bike"
        ThingHomeSdk.getHomeManagerInstance().createHome(
            name,
            0.0,
            0.0,
            "",
            arrayListOf<String>(),
            object : IThingHomeResultCallback {
                override fun onSuccess(bean: HomeBean) {
                    result.success(
                        mapOf(
                            "success" to true,
                            "tuya_home_id" to bean.homeId.toString(),
                            "name" to (bean.name ?: name),
                            "code" to "",
                            "message" to "Tuya home created",
                        )
                    )
                }

                override fun onError(code: String?, error: String?) {
                    result.success(
                        mapOf(
                            "success" to false,
                            "tuya_home_id" to "",
                            "name" to name,
                            "code" to safeTuyaErrorCode(code),
                            "message" to safeTuyaErrorMessage(error),
                        )
                    )
                }
            }
        )
    }

    private fun startTuyaWifiPairing(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(
                mapOf(
                    "success" to false,
                    "code" to "tuya_not_initialized",
                    "message" to DoctorBikeApplication.tuyaInitializationMessage,
                    "device" to emptyMap<String, Any?>(),
                )
            )
            return
        }

        val tuyaHomeId = call.argument<String>("tuyaHomeId")?.toLongOrNull() ?: 0L
        val ssid = call.argument<String>("ssid") ?: ""
        val password = call.argument<String>("password") ?: ""
        if (tuyaHomeId <= 0L || ssid.isBlank()) {
            result.success(
                mapOf(
                    "success" to false,
                    "code" to "missing_pairing_arguments",
                    "message" to "Missing Tuya home id or WiFi name",
                    "device" to emptyMap<String, Any?>(),
                )
            )
            return
        }

        stopSmartHomeActivator()
        val completed = AtomicBoolean(false)
        ThingHomeSdk.getActivatorInstance().getActivatorToken(
            tuyaHomeId,
            object : IThingActivatorGetToken {
                override fun onSuccess(token: String) {
                    val builder = ActivatorBuilder()
                        .setContext(applicationContext)
                        .setSsid(ssid)
                        .setPassword(password)
                        .setToken(token)
                        .setTimeOut(120)
                        .setActivatorModel(ActivatorModelEnum.THING_EZ)
                        .setListener(object : IThingSmartActivatorListener {
                            override fun onError(code: String?, error: String?) {
                                if (completed.compareAndSet(false, true)) {
                                    stopSmartHomeActivator()
                                    result.success(
                                        mapOf(
                                            "success" to false,
                                            "code" to safeTuyaErrorCode(code),
                                            "message" to safeTuyaErrorMessage(error),
                                            "device" to emptyMap<String, Any?>(),
                                        )
                                    )
                                }
                            }

                            override fun onActiveSuccess(deviceBean: DeviceBean) {
                                if (completed.compareAndSet(false, true)) {
                                    stopSmartHomeActivator()
                                    result.success(
                                        mapOf(
                                            "success" to true,
                                            "code" to "",
                                            "message" to "Device paired",
                                            "device" to mapDeviceBean(deviceBean),
                                        )
                                    )
                                }
                            }

                            override fun onStep(step: String, data: Any?) {
                                Log.d("DoctorBikeTuya", "Pairing step=$step data=$data")
                            }
                        })

                    activeSmartHomeActivator = ThingHomeSdk.getActivatorInstance()
                        .newEZWifiConfigDevActivator(builder)
                    activeSmartHomeActivator?.start()
                }

                override fun onFailure(code: String, error: String) {
                    if (completed.compareAndSet(false, true)) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "code" to safeTuyaErrorCode(code),
                                "message" to safeTuyaErrorMessage(error),
                                "device" to emptyMap<String, Any?>(),
                            )
                        )
                    }
                }
            }
        )
    }


    private fun scanTuyaBluetoothDevices(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(
                mapOf(
                    "success" to false,
                    "code" to "tuya_not_initialized",
                    "message" to DoctorBikeApplication.tuyaInitializationMessage,
                    "devices" to emptyList<Map<String, Any?>>()
                )
            )
            return
        }

        val timeoutMs = call.argument<Int>("timeoutMs") ?: 10000
        val devices = linkedMapOf<String, ScanDeviceBean>()
        val completed = AtomicBoolean(false)
        val scanSetting = LeScanSetting.Builder()
            .setTimeout(timeoutMs.toLong())
            .addScanType(ScanType.SINGLE)
            .setRepeatFilter(true)
            .build()

        fun finish() {
            if (completed.compareAndSet(false, true)) {
                runCatching { ThingHomeSdk.getBleOperator().stopLeScan() }
                result.success(
                    mapOf(
                        "success" to true,
                        "code" to "",
                        "message" to "Bluetooth scan completed",
                        "devices" to devices.values.map { mapScanDeviceBean(it) }
                    )
                )
            }
        }

        runCatching { ThingHomeSdk.getBleOperator().stopLeScan() }
        ThingHomeSdk.getBleOperator().startLeScan(scanSetting, object : BleScanResponse {
            override fun onResult(bean: ScanDeviceBean) {
                val key = bean.uuid ?: bean.id ?: bean.address ?: bean.mac ?: return
                devices[key] = bean
            }
        })
        smartHomeHandler.postDelayed({ finish() }, timeoutMs.toLong() + 600L)
    }

    private fun startTuyaBluetoothPairing(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(
                mapOf(
                    "success" to false,
                    "code" to "tuya_not_initialized",
                    "message" to DoctorBikeApplication.tuyaInitializationMessage,
                    "device" to emptyMap<String, Any?>()
                )
            )
            return
        }

        val tuyaHomeId = call.argument<String>("tuyaHomeId")?.toLongOrNull() ?: 0L
        val ssid = call.argument<String>("ssid") ?: ""
        val password = call.argument<String>("password") ?: ""
        val scanDevice = scanDeviceBeanFromMap(call.argument<Map<String, Any?>>("scanDevice") ?: emptyMap())
        if (tuyaHomeId <= 0L || scanDevice.uuid.isNullOrBlank()) {
            result.success(
                mapOf(
                    "success" to false,
                    "code" to "missing_ble_pairing_arguments",
                    "message" to "Missing Tuya home id or Bluetooth device UUID",
                    "device" to emptyMap<String, Any?>()
                )
            )
            return
        }

        val completed = AtomicBoolean(false)
        fun fail(code: String, message: String) {
            if (completed.compareAndSet(false, true)) {
                runCatching { ThingHomeSdk.getBleManager().stopBleConfig(scanDevice.uuid) }
                runCatching { ThingHomeSdk.getActivator().newMultiModeActivator().stopActivator(scanDevice.uuid) }
                result.success(
                    mapOf(
                        "success" to false,
                        "code" to safeTuyaErrorCode(code),
                        "message" to message,
                        "device" to emptyMap<String, Any?>()
                    )
                )
            }
        }

        fun success(deviceBean: DeviceBean) {
            if (completed.compareAndSet(false, true)) {
                result.success(
                    mapOf(
                        "success" to true,
                        "code" to "",
                        "message" to "Bluetooth device paired",
                        "device" to mapDeviceBean(deviceBean)
                    )
                )
            }
        }

        ThingHomeSdk.getActivatorInstance().getActivatorToken(
            tuyaHomeId,
            object : IThingActivatorGetToken {
                override fun onSuccess(token: String) {
                    if (scanDevice.configType == "config_type_wifi") {
                        val bean = MultiModeActivatorBean(scanDevice)
                        bean.homeId = tuyaHomeId
                        bean.uuid = scanDevice.uuid
                        bean.address = scanDevice.address
                        bean.deviceType = scanDevice.deviceType
                        bean.flag = scanDevice.flag
                        bean.mac = scanDevice.mac
                        bean.productId = scanDevice.productId
                        bean.ssid = ssid
                        bean.pwd = password
                        bean.token = token
                        bean.timeout = 120000L
                        bean.phase1Timeout = 60000L
                        ThingHomeSdk.getActivator().newMultiModeActivator().startActivator(
                            bean,
                            object : IMultiModeActivatorListener {
                                override fun onSuccess(deviceBean: DeviceBean) = success(deviceBean)
                                override fun onFailure(code: Int, msg: String, handle: Any?) = fail(code.toString(), msg)
                            }
                        )
                    } else {
                        val bean = BleActivatorBean(scanDevice)
                        bean.homeId = tuyaHomeId
                        bean.uuid = scanDevice.uuid
                        bean.address = scanDevice.address
                        bean.productId = scanDevice.productId
                        bean.deviceType = scanDevice.deviceType
                        bean.isShare = scanDevice.isShare
                        bean.timeout = 60000L
                        ThingHomeSdk.getActivator().newBleActivator().startActivator(
                            bean,
                            object : IBleActivatorListener {
                                override fun onSuccess(deviceBean: DeviceBean) = success(deviceBean)
                                override fun onFailure(code: Int, msg: String, handle: Any?) = fail(code.toString(), msg)
                            }
                        )
                    }
                }

                override fun onFailure(code: String, error: String) = fail(code, error)
            }
        )
    }

    private fun getTuyaDeviceStatus(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(deviceResult(false, "tuya_not_initialized", DoctorBikeApplication.tuyaInitializationMessage, null))
            return
        }

        val devId = call.argument<String>("tuyaDeviceId") ?: ""
        val homeId = call.argument<String>("tuyaHomeId") ?: ""
        if (devId.isBlank()) {
            result.success(deviceResult(false, "missing_device_id", "Missing Tuya device id", null))
            return
        }

        withTuyaDeviceBean(devId, homeId, result) { deviceBean ->
            result.success(deviceResult(true, "", "Device status loaded", deviceBean))
        }
    }

    private fun renameTuyaDevice(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(deviceResult(false, "tuya_not_initialized", DoctorBikeApplication.tuyaInitializationMessage, null))
            return
        }

        val devId = call.argument<String>("tuyaDeviceId") ?: ""
        val name = call.argument<String>("name") ?: ""
        if (devId.isBlank() || name.isBlank()) {
            result.success(deviceResult(false, "missing_rename_arguments", "Missing Tuya device id or name", null))
            return
        }

        val device = ThingHomeSdk.newDeviceInstance(devId)
        device.renameDevice(name, object : IResultCallback {
            override fun onSuccess() {
                val bean = ThingHomeSdk.getDataInstance().getDeviceBean(devId)
                result.success(deviceResult(true, "", "Device renamed", bean))
                device.onDestroy()
            }

            override fun onError(code: String?, error: String?) {
                result.success(deviceResult(false, safeTuyaErrorCode(code), safeTuyaErrorMessage(code, error), ThingHomeSdk.getDataInstance().getDeviceBean(devId)))
                device.onDestroy()
            }
        })
    }

    private fun removeTuyaDevice(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(deviceResult(false, "tuya_not_initialized", DoctorBikeApplication.tuyaInitializationMessage, null))
            return
        }

        val devId = call.argument<String>("tuyaDeviceId") ?: ""
        val homeId = call.argument<String>("tuyaHomeId") ?: ""
        if (devId.isBlank()) {
            result.success(deviceResult(false, "missing_device_id", "Missing Tuya device id", null))
            return
        }

        withTuyaDeviceBean(devId, homeId, result) { bean ->
            val device = ThingHomeSdk.newDeviceInstance(devId)
            device.removeDevice(object : IResultCallback {
                override fun onSuccess() {
                    result.success(deviceResult(true, "", "Device removed", bean))
                    device.onDestroy()
                }

                override fun onError(code: String?, error: String?) {
                    result.success(
                        deviceResult(
                            false,
                            safeTuyaErrorCode(code),
                            safeTuyaErrorMessage(code, error),
                            ThingHomeSdk.getDataInstance().getDeviceBean(devId),
                        )
                    )
                    device.onDestroy()
                }
            })
        }
    }

    private fun publishTuyaDps(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (!DoctorBikeApplication.tuyaInitialized) {
            result.success(deviceResult(false, "tuya_not_initialized", DoctorBikeApplication.tuyaInitializationMessage, null))
            return
        }

        val devId = call.argument<String>("tuyaDeviceId") ?: ""
        val homeId = call.argument<String>("tuyaHomeId") ?: ""
        val requestedDpId = call.argument<String>("dpId") ?: ""
        val requestedCode = call.argument<String>("code") ?: ""
        val requestedType = call.argument<String>("type") ?: ""
        val requestedValue = call.argument<Any?>("value")
        if (devId.isBlank() || requestedDpId.isBlank()) {
            result.success(deviceResult(false, "missing_dps_arguments", "Missing Tuya device id or DP id", null))
            return
        }

        withTuyaDeviceBean(devId, homeId, result) { bean ->
            val schema = resolveWritableSchema(bean, requestedDpId, requestedCode)
            if (schema == null) {
                val response = deviceResult(false, "unsupported_or_read_only_dp", "No writable Tuya function matched DP $requestedDpId / $requestedCode", bean).toMutableMap()
                response["submitted"] = mapOf(
                    "dp_id" to requestedDpId,
                    "code" to requestedCode,
                    "type" to requestedType,
                    "value_type" to (requestedValue?.javaClass?.simpleName ?: "null"),
                )
                result.success(response)
                return@withTuyaDeviceBean
            }

            val validation = validateTuyaValue(schema, requestedValue)
            if (!validation.first) {
                val response = deviceResult(false, "invalid_dp_value", validation.second ?: "Invalid Tuya DP value", bean).toMutableMap()
                response["resolved_function"] = mapSchemaBean(schema)
                response["submitted"] = mapOf(
                    "dp_id" to requestedDpId,
                    "code" to requestedCode,
                    "type" to requestedType,
                    "value_type" to (requestedValue?.javaClass?.simpleName ?: "null"),
                )
                result.success(response)
                return@withTuyaDeviceBean
            }

            val publishDpId = schema.id?.takeIf { it.isNotBlank() } ?: requestedDpId
            val dps = linkedMapOf<String, Any?>(publishDpId to requestedValue)
            val device = ThingHomeSdk.newDeviceInstance(devId)
            val payload = JSONObject(dps).toString()
            device.publishDps(payload, object : IResultCallback {
                override fun onSuccess() {
                    val bean = ThingHomeSdk.getDataInstance().getDeviceBean(devId)
                    val response = deviceResult(true, "", "DPS command published", bean).toMutableMap()
                    response["resolved_function"] = mapSchemaBean(schema)
                    val merged = linkedMapOf<String, Any?>()
                    if (bean?.dps != null) merged.putAll(bean.dps)
                    merged.putAll(dps)
                    response["dps"] = merged
                    response["online"] = bean?.isOnline == true
                    result.success(response)
                    device.onDestroy()
                }

                override fun onError(code: String?, error: String?) {
                    val latestBean = ThingHomeSdk.getDataInstance().getDeviceBean(devId)
                    val response = deviceResult(false, safeTuyaErrorCode(code), safeTuyaErrorMessage(code, error), latestBean).toMutableMap()
                    response["resolved_function"] = mapSchemaBean(schema)
                    response["submitted"] = mapOf(
                        "dp_id" to publishDpId,
                        "code" to (schema.code ?: requestedCode),
                        "type" to (schema.type ?: requestedType),
                        "value_type" to (requestedValue?.javaClass?.simpleName ?: "null"),
                    )
                    result.success(response)
                    device.onDestroy()
                }
            })
        }
    }

    private fun withTuyaDeviceBean(
        devId: String,
        homeId: String,
        result: MethodChannel.Result,
        onReady: (DeviceBean) -> Unit,
    ) {
        val cached = ThingHomeSdk.getDataInstance().getDeviceBean(devId)
        if (cached != null) {
            onReady(cached)
            return
        }

        val tuyaHomeId = homeId.toLongOrNull()
        if (tuyaHomeId == null || tuyaHomeId <= 0L) {
            result.success(
                deviceResult(
                    false,
                    "device_not_found",
                    "Device was not found in Tuya cache and no Tuya home id was provided for refresh",
                    null,
                )
            )
            return
        }

        val home = ThingHomeSdk.newHomeInstance(tuyaHomeId)
        home.getHomeDetail(object : IThingHomeResultCallback {
            override fun onSuccess(bean: HomeBean) {
                val refreshed = ThingHomeSdk.getDataInstance().getDeviceBean(devId)
                if (refreshed == null) {
                    result.success(
                        deviceResult(
                            false,
                            "device_not_found",
                            "Device was not found in Tuya cache after home refresh",
                            null,
                        )
                    )
                    home.onDestroy()
                    return
                }
                onReady(refreshed)
                home.onDestroy()
            }

            override fun onError(code: String?, error: String?) {
                result.success(
                    deviceResult(
                        false,
                        safeTuyaErrorCode(code),
                        safeTuyaErrorMessage(code, error),
                        null,
                    )
                )
                home.onDestroy()
            }
        })
    }

    private fun resolveWritableSchema(
        deviceBean: DeviceBean?,
        dpId: String,
        code: String,
    ): com.thingclips.smart.android.device.bean.SchemaBean? {
        val schemaMap = deviceBean?.schemaMap ?: return null
        val direct = schemaMap[dpId]
        if (direct != null && isWritableSchema(direct) && (code.isBlank() || direct.code == code || direct.id == dpId)) {
            return direct
        }
        return schemaMap.values.firstOrNull { schema ->
            isWritableSchema(schema) && (schema.id == dpId || schema.code == code)
        }
    }

    private fun isWritableSchema(schema: com.thingclips.smart.android.device.bean.SchemaBean): Boolean {
        return (schema.mode ?: "").lowercase().contains("w")
    }

    private fun validateTuyaValue(
        schema: com.thingclips.smart.android.device.bean.SchemaBean,
        value: Any?,
    ): Pair<Boolean, String?> {
        return when ((schema.type ?: "").lowercase()) {
            "bool" -> Pair(value is Boolean, "Expected boolean for ${schema.code}")
            "enum" -> {
                val range = runCatching {
                    JSONObject(schema.property ?: "{}").optJSONArray("range")
                }.getOrNull()
                val submitted = value?.toString()
                val valid = submitted != null && (range == null || (0 until range.length()).any { range.optString(it) == submitted })
                Pair(valid, "Invalid enum value for ${schema.code}")
            }
            "value" -> {
                val number = value as? Number ?: return Pair(false, "Expected numeric value for ${schema.code}")
                val property = runCatching { JSONObject(schema.property ?: "{}") }.getOrNull()
                val min = property?.optDouble("min", Double.NaN)
                val max = property?.optDouble("max", Double.NaN)
                val submitted = number.toDouble()
                if (min != null && !min.isNaN() && submitted < min) return Pair(false, "${schema.code} is below min $min")
                if (max != null && !max.isNaN() && submitted > max) return Pair(false, "${schema.code} is above max $max")
                Pair(true, null)
            }
            "string" -> Pair(value is String, "Expected string for ${schema.code}")
            else -> Pair(false, "Unsupported Tuya DP type ${schema.type} for ${schema.code}")
        }
    }

    private fun mapSchemaBean(schema: com.thingclips.smart.android.device.bean.SchemaBean): Map<String, Any?> {
        return mapOf(
            "id" to (schema.id ?: ""),
            "code" to (schema.code ?: ""),
            "name" to (schema.name ?: ""),
            "mode" to (schema.mode ?: ""),
            "type" to (schema.type ?: ""),
            "property" to (schema.property ?: ""),
            "schema_type" to (schema.schemaType ?: ""),
        )
    }
    private fun safeTuyaErrorCode(code: String?): String {
        return code?.takeIf { it.isNotBlank() } ?: "tuya_error"
    }

    private fun safeTuyaErrorMessage(error: String?): String {
        return safeTuyaErrorMessage(null, error)
    }

    private fun safeTuyaErrorMessage(code: String?, error: String?): String {
        val clean = error?.takeIf { it.isNotBlank() }
        if (clean != null) return clean
        return when (safeTuyaErrorCode(code)) {
            "11001" -> "Tuya error 11001: Invalid command format"
            "11002" -> "Tuya error 11002: Device removed"
            "11004" -> "Tuya error 11004: Invalid signature"
            "11005" -> "Tuya error 11005: Failed to send data"
            "11009" -> "Tuya error 11009: Empty data"
            "10203" -> "Tuya error 10203: Device offline"
            else -> "Tuya returned an empty error message"
        }
    }
    private fun deviceResult(
        success: Boolean,
        code: String,
        message: String,
        deviceBean: DeviceBean?
    ): Map<String, Any?> {
        return mapOf(
            "success" to success,
            "code" to safeTuyaErrorCode(code),
            "message" to message,
            "device" to if (deviceBean != null) mapDeviceBean(deviceBean) else emptyMap<String, Any?>(),
            "dps" to (deviceBean?.dps ?: emptyMap<String, Any?>()),
            "online" to (deviceBean?.isOnline == true),
        )
    }
    private fun mapScanDeviceBean(device: ScanDeviceBean): Map<String, Any?> {
        return mapOf(
            "id" to (device.id ?: ""),
            "name" to (device.name ?: ""),
            "provider_name" to (device.providerName ?: ""),
            "config_type" to (device.configType ?: ""),
            "product_id" to (device.productId ?: ""),
            "uuid" to (device.uuid ?: ""),
            "mac" to (device.mac ?: ""),
            "address" to (device.address ?: ""),
            "device_type" to device.deviceType,
            "flag" to device.flag,
            "rssi" to device.rssi,
            "is_bind" to device.getIsbind(),
            "is_share" to device.isShare
        )
    }

    private fun scanDeviceBeanFromMap(map: Map<String, Any?>): ScanDeviceBean {
        val bean = ScanDeviceBean()
        bean.id = map["id"]?.toString() ?: ""
        bean.name = map["name"]?.toString() ?: ""
        bean.providerName = map["provider_name"]?.toString() ?: ""
        bean.configType = map["config_type"]?.toString() ?: ""
        bean.productId = map["product_id"]?.toString() ?: ""
        bean.uuid = map["uuid"]?.toString() ?: ""
        bean.mac = map["mac"]?.toString() ?: ""
        bean.address = map["address"]?.toString() ?: ""
        bean.deviceType = (map["device_type"] as? Number)?.toInt() ?: 0
        bean.flag = (map["flag"] as? Number)?.toInt() ?: 0
        bean.rssi = (map["rssi"] as? Number)?.toInt() ?: 0
        bean.setShare(map["is_share"] == true)
        bean.setIsbind(map["is_bind"] == true)
        return bean
    }
    private fun stopSmartHomeActivator() {
        runCatching { activeSmartHomeActivator?.stop() }
        runCatching { activeSmartHomeActivator?.onDestroy() }
        activeSmartHomeActivator = null
    }

    private fun mapDeviceBean(device: DeviceBean): Map<String, Any?> {
        return mapOf(
            "tuya_device_id" to (device.devId ?: ""),
            "tuya_product_id" to device.productId,
            "tuya_uuid" to device.uuid,
            "name" to (device.name ?: "Smart device"),
            "category" to device.category,
            "product_name" to (device.productId ?: device.category ?: ""),
            "icon" to device.iconUrl,
            "protocol" to "wifi",
            "online" to (device.isOnline == true),
            "last_status" to (device.dps ?: emptyMap<String, Any?>()),
            "schema_map" to mapSchemaMap(device.schemaMap),
            "schema" to (device.schema ?: ""),
        )
    }
    private fun mapSchemaMap(schemaMap: Map<String, com.thingclips.smart.android.device.bean.SchemaBean>?): Map<String, Any?> {
        if (schemaMap == null) return emptyMap()
        return schemaMap.mapValues { (_, schema) -> mapSchemaBean(schema) }
    }
    private fun checkAvailability(): Map<String, Any> {
        val manager = BiometricManager.from(this)
        val strongCode = manager.canAuthenticate(strong)
        val weakCode = manager.canAuthenticate(weak)
        val credentialCode = manager.canAuthenticate(strongOrCredential)
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val deviceSecure = keyguardManager.isDeviceSecure
        val available = strongCode == BiometricManager.BIOMETRIC_SUCCESS ||
            weakCode == BiometricManager.BIOMETRIC_SUCCESS ||
            credentialCode == BiometricManager.BIOMETRIC_SUCCESS ||
            deviceSecure
        val code = when {
            strongCode == BiometricManager.BIOMETRIC_SUCCESS -> strongCode
            weakCode == BiometricManager.BIOMETRIC_SUCCESS -> weakCode
            credentialCode == BiometricManager.BIOMETRIC_SUCCESS -> credentialCode
            deviceSecure -> 0
            else -> strongCode
        }
        return mapOf(
            "available" to available,
            "code" to code,
            "message" to messageForCode(code),
        )
    }

    private fun handleKeyguardActivityResult(resultCode: Int, mode: String) {
        if (isKeyguardAuthenticationSuccess(resultCode)) {
            completeKeyguard(true, 0, "تم التحقق بنجاح", mode)
        } else {
            completeKeyguard(
                success = false,
                code = "user_cancelled_or_not_completed",
                message = "تم إلغاء التحقق أو لم يتم إكمال قفل الجهاز",
                mode = mode,
            )
        }
    }

    /** Some Samsung/One UI builds return vendor-specific positive codes on success. */
    private fun isKeyguardAuthenticationSuccess(resultCode: Int): Boolean {
        if (resultCode == Activity.RESULT_OK) return true
        return resultCode > 0
    }

    private fun authenticate(result: MethodChannel.Result, authenticators: Int, mode: String) {
        logAvailability(mode, authenticators)
        val availabilityCode = BiometricManager.from(this).canAuthenticate(authenticators)
        if (availabilityCode != BiometricManager.BIOMETRIC_SUCCESS) {
            result.success(
                mapOf(
                    "success" to false,
                    "available" to false,
                    "code" to availabilityCode,
                    "message" to messageForCode(availabilityCode),
                    "mode" to mode,
                )
            )
            return
        }

        val completed = AtomicBoolean(false)
        val executor = ContextCompat.getMainExecutor(this)
        val prompt = BiometricPrompt(
            this,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    Log.d("DrBikeBiometric", "Native authentication succeeded mode=$mode")
                    if (completed.compareAndSet(false, true)) {
                        result.success(
                            mapOf(
                                "success" to true,
                                "available" to true,
                                "code" to 0,
                                "message" to "تم التحقق بنجاح",
                                "mode" to mode,
                            )
                        )
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    Log.d("DrBikeBiometric", "Native authentication error mode=$mode code=$errorCode message=$errString")
                    if (completed.compareAndSet(false, true)) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "available" to true,
                                "code" to errorCode,
                                "message" to errString.toString(),
                                "mode" to mode,
                            )
                        )
                    }
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    Log.d("DrBikeBiometric", "Native authentication failed mode=$mode; allowing retry")
                }
            },
        )

        val promptBuilder = BiometricPrompt.PromptInfo.Builder()
            .setTitle("تأكيد الهوية")
            .setSubtitle(subtitleForMode(mode))
            .setAllowedAuthenticators(authenticators)

        if (authenticators and deviceCredential == 0) {
            promptBuilder.setNegativeButtonText("إلغاء")
        }

        val promptInfo = promptBuilder.build()

        Log.d(
            "DrBikeBiometric",
            "Before prompt post mode=$mode lifecycle=${lifecycle.currentState} " +
                "hasFocus=${window?.decorView?.hasWindowFocus()} isFinishing=$isFinishing isDestroyed=$isDestroyed"
        )
        runOnUiThread {
            window.decorView.postDelayed({
                Log.d(
                    "DrBikeBiometric",
                    "Inside prompt post mode=$mode lifecycle=${lifecycle.currentState} " +
                        "hasFocus=${window?.decorView?.hasWindowFocus()} isFinishing=$isFinishing isDestroyed=$isDestroyed"
                )
                if (!lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED) || isFinishing || isDestroyed) {
                    if (completed.compareAndSet(false, true)) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "available" to true,
                                "code" to -100,
                                "message" to "الشاشة غير جاهزة لفتح نافذة البصمة، حاول مرة أخرى",
                                "mode" to mode,
                            )
                        )
                    }
                    return@postDelayed
                }

                Log.d("DrBikeBiometric", "Showing native biometric prompt mode=$mode authenticators=$authenticators")
                try {
                    prompt.authenticate(promptInfo)
                } catch (e: Exception) {
                    Log.d("DrBikeBiometric", "Native authenticate exception mode=$mode message=${e.message}")
                    if (completed.compareAndSet(false, true)) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "available" to true,
                                "code" to "authenticate_exception",
                                "message" to (e.message ?: "تعذر فتح نافذة البصمة"),
                                "mode" to mode,
                            )
                        )
                    }
                }
            }, 500)
        }
    }

    private fun authenticateKeyguard(result: MethodChannel.Result) {
        authenticateKeyguardDirect(result, mode = "keyguard")
    }

    private fun authenticateKeyguardDirect(result: MethodChannel.Result, mode: String = "keyguardDirect") {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        Log.d(
            "DrBikeBiometric",
            "Keyguard start mode=$mode lifecycle=${lifecycle.currentState} hasFocus=${window?.decorView?.hasWindowFocus()} " +
                "isFinishing=$isFinishing isDestroyed=$isDestroyed isDeviceSecure=${keyguardManager.isDeviceSecure}"
        )

        if (!keyguardManager.isDeviceSecure) {
            result.success(
                mapOf(
                    "success" to false,
                    "available" to false,
                    "code" to "device_not_secure",
                    "message" to "يرجى تفعيل قفل الشاشة من إعدادات الجهاز",
                    "mode" to mode,
                )
            )
            return
        }

        if (pendingKeyguardResult != null) {
            result.success(
                mapOf(
                    "success" to false,
                    "available" to true,
                    "code" to "keyguard_in_progress",
                    "message" to "عملية التحقق قيد التنفيذ",
                    "mode" to mode,
                )
            )
            return
        }

        val intent = keyguardManager.createConfirmDeviceCredentialIntent(
            "تأكيد الهوية",
            "استخدم قفل الجهاز لتسجيل الدخول"
        )

        if (intent == null) {
            launchKeyguardProxyFallback(result, mode)
            return
        }

        pendingKeyguardResult = result
        pendingKeyguardMode = mode
        runOnUiThread {
            window.decorView.postDelayed({
                Log.d(
                    "DrBikeBiometric",
                    "Keyguard post mode=$mode lifecycle=${lifecycle.currentState} hasFocus=${window?.decorView?.hasWindowFocus()} " +
                        "isFinishing=$isFinishing isDestroyed=$isDestroyed"
                )
                if (!lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED) || isFinishing || isDestroyed) {
                    completeKeyguard(
                        success = false,
                        code = "activity_not_resumed",
                        message = "الشاشة غير جاهزة لفتح نافذة البصمة، حاول مرة أخرى",
                        mode = mode,
                    )
                    return@postDelayed
                }
                try {
                    Log.d("DrBikeBiometric", "Before keyguardDirectLauncher.launch mode=$mode")
                    keyguardLaunchStartedAt = System.currentTimeMillis()
                    keyguardDirectLauncher.launch(intent)
                    Log.d("DrBikeBiometric", "After keyguardDirectLauncher.launch mode=$mode")
                } catch (e: Exception) {
                    Log.d("DrBikeBiometric", "Keyguard launch exception mode=$mode message=${e.message}")
                    launchKeyguardProxyFallback(result, mode)
                }
            }, 500)
        }
    }

    private var pendingKeyguardMode: String = "keyguard"

    private fun launchKeyguardProxyFallback(result: MethodChannel.Result, mode: String) {
        Log.d("DrBikeBiometric", "Falling back to proxy keyguard mode=$mode")
        if (pendingKeyguardResult != null) {
            result.success(
                mapOf(
                    "success" to false,
                    "available" to true,
                    "code" to "keyguard_in_progress",
                    "message" to "عملية التحقق قيد التنفيذ",
                    "mode" to "keyguardProxy",
                )
            )
            return
        }
        pendingKeyguardResult = result
        pendingKeyguardMode = "keyguardProxy"
        runOnUiThread {
            window.decorView.postDelayed({
                if (!lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED) || isFinishing || isDestroyed) {
                    completeKeyguard(
                        success = false,
                        code = "activity_not_resumed",
                        message = "الشاشة غير جاهزة لفتح نافذة البصمة، حاول مرة أخرى",
                        mode = "keyguardProxy",
                    )
                    return@postDelayed
                }
                try {
                    keyguardLaunchStartedAt = System.currentTimeMillis()
                    biometricProxyLauncher.launch(Intent(this, BiometricProxyActivity::class.java))
                } catch (e: Exception) {
                    completeKeyguard(
                        success = false,
                        code = "proxy_launch_exception",
                        message = e.message ?: "تعذر فتح شاشة قفل الجهاز",
                        mode = "keyguardProxy",
                    )
                }
            }, 500)
        }
    }

    private fun openSecuritySettings(result: MethodChannel.Result) {
        try {
            Log.d("DrBikeBiometric", "Opening Android security settings")
            startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
            result.success(
                mapOf(
                    "success" to true,
                    "available" to true,
                    "code" to 0,
                    "message" to "تم فتح إعدادات الأمان",
                    "mode" to "securitySettings",
                )
            )
        } catch (e: Exception) {
            Log.d("DrBikeBiometric", "Open security settings exception message=${e.message}")
            result.success(
                mapOf(
                    "success" to false,
                    "available" to false,
                    "code" to "security_settings_exception",
                    "message" to (e.message ?: "تعذر فتح إعدادات الأمان"),
                    "mode" to "securitySettings",
                )
            )
        }
    }

    private fun completeKeyguard(
        success: Boolean,
        code: Any,
        message: String,
        mode: String = pendingKeyguardMode,
    ) {
        val result = pendingKeyguardResult
        pendingKeyguardResult = null
        pendingKeyguardMode = "keyguard"
        keyguardLaunchStartedAt = 0L
        result?.success(
            mapOf(
                "success" to success,
                "available" to true,
                "code" to code,
                "message" to message,
                "mode" to mode,
            )
        )
    }

    private fun logAvailability(mode: String, authenticators: Int) {
        val code = BiometricManager.from(this).canAuthenticate(authenticators)
        Log.d(
            "DrBikeBiometric",
            "canAuthenticate mode=$mode authenticators=$authenticators code=$code message=${messageForCode(code)}"
        )
        Log.d("DrBikeBiometric", "canAuthenticate strong code=${BiometricManager.from(this).canAuthenticate(strong)}")
        Log.d("DrBikeBiometric", "canAuthenticate weak code=${BiometricManager.from(this).canAuthenticate(weak)}")
        Log.d("DrBikeBiometric", "canAuthenticate credential code=${BiometricManager.from(this).canAuthenticate(deviceCredential)}")
        Log.d("DrBikeBiometric", "canAuthenticate strongOrCredential code=${BiometricManager.from(this).canAuthenticate(strongOrCredential)}")
    }

    private fun subtitleForMode(mode: String): String {
        return when (mode) {
            "strong" -> "استخدم بصمة قوية لتسجيل الدخول"
            "weak" -> "استخدم البصمة أو الوجه لتسجيل الدخول"
            "deviceCredential" -> "استخدم قفل الجهاز لتسجيل الدخول"
            "strongOrCredential" -> "استخدم البصمة أو قفل الجهاز لتسجيل الدخول"
            else -> "استخدم البصمة أو قفل الجهاز لتسجيل الدخول"
        }
    }

    private fun messageForCode(code: Int): String {
        return when (code) {
            BiometricManager.BIOMETRIC_SUCCESS -> "المصادقة الحيوية متاحة"
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> "جهازك لا يدعم البصمة أو التعرف على الوجه"
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "مستشعر البصمة غير متاح حالياً"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "يرجى تفعيل البصمة أو قفل الشاشة من إعدادات الجهاز أولاً"
            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> "يلزم تحديث أمان الجهاز لتفعيل البصمة"
            BiometricManager.BIOMETRIC_ERROR_UNSUPPORTED -> "طريقة التحقق غير مدعومة على هذا الجهاز"
            BiometricManager.BIOMETRIC_STATUS_UNKNOWN -> "حالة المصادقة الحيوية غير معروفة"
            else -> "تعذر التحقق من توفر البصمة"
        }
    }
}



