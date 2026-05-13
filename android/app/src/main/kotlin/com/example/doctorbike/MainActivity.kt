package com.nofal.doctorbike

import android.app.KeyguardManager
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.lifecycle.Lifecycle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "dr_bike/biometric"
    private val strong = BiometricManager.Authenticators.BIOMETRIC_STRONG
    private val weak = BiometricManager.Authenticators.BIOMETRIC_WEAK
    private val deviceCredential = BiometricManager.Authenticators.DEVICE_CREDENTIAL
    private val strongOrCredential = strong or deviceCredential
    private val keyguardRequestCode = 9001
    private var pendingKeyguardResult: MethodChannel.Result? = null

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
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkAvailability(): Map<String, Any> {
        val code = BiometricManager.from(this).canAuthenticate(strong)
        return mapOf(
            "available" to (code == BiometricManager.BIOMETRIC_SUCCESS),
            "code" to code,
            "message" to messageForCode(code),
        )
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
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        Log.d(
            "DrBikeBiometric",
            "Keyguard start lifecycle=${lifecycle.currentState} hasFocus=${window?.decorView?.hasWindowFocus()} " +
                "isFinishing=$isFinishing isDestroyed=$isDestroyed isDeviceSecure=${keyguardManager.isDeviceSecure}"
        )

        if (!keyguardManager.isDeviceSecure) {
            result.success(
                mapOf(
                    "success" to false,
                    "available" to false,
                    "code" to "device_not_secure",
                    "message" to "يرجى تفعيل قفل الشاشة من إعدادات الجهاز",
                    "mode" to "keyguard",
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
                    "mode" to "keyguard",
                )
            )
            return
        }

        val intent = keyguardManager.createConfirmDeviceCredentialIntent(
            "تأكيد الهوية",
            "استخدم قفل الجهاز لتسجيل الدخول"
        )

        if (intent == null) {
            result.success(
                mapOf(
                    "success" to false,
                    "available" to false,
                    "code" to "keyguard_intent_null",
                    "message" to "تعذر فتح شاشة قفل الجهاز",
                    "mode" to "keyguard",
                )
            )
            return
        }

        pendingKeyguardResult = result
        runOnUiThread {
            window.decorView.postDelayed({
                Log.d(
                    "DrBikeBiometric",
                    "Keyguard post lifecycle=${lifecycle.currentState} hasFocus=${window?.decorView?.hasWindowFocus()} " +
                        "isFinishing=$isFinishing isDestroyed=$isDestroyed"
                )
                if (!lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED) || isFinishing || isDestroyed) {
                    completeKeyguard(
                        success = false,
                        code = "activity_not_resumed",
                        message = "الشاشة غير جاهزة لفتح نافذة البصمة، حاول مرة أخرى"
                    )
                    return@postDelayed
                }
                try {
                    startActivityForResult(intent, keyguardRequestCode)
                } catch (e: Exception) {
                    Log.d("DrBikeBiometric", "Keyguard launch exception message=${e.message}")
                    completeKeyguard(
                        success = false,
                        code = "keyguard_launch_exception",
                        message = e.message ?: "تعذر فتح شاشة قفل الجهاز"
                    )
                }
            }, 500)
        }
    }

    @Deprecated("Deprecated in Android API, kept for KeyguardManager compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == keyguardRequestCode) {
            Log.d("DrBikeBiometric", "Keyguard resultCode=$resultCode")
            if (resultCode == Activity.RESULT_OK) {
                completeKeyguard(true, 0, "تم التحقق بنجاح")
            } else {
                completeKeyguard(false, resultCode, "تم إلغاء عملية التحقق")
            }
        }
    }

    private fun completeKeyguard(success: Boolean, code: Any, message: String) {
        val result = pendingKeyguardResult
        pendingKeyguardResult = null
        result?.success(
            mapOf(
                "success" to success,
                "available" to true,
                "code" to code,
                "message" to message,
                "mode" to "keyguard",
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
