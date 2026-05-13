package com.nofal.doctorbike

import android.util.Log
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
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

        Log.d("DrBikeBiometric", "Showing native biometric prompt mode=$mode authenticators=$authenticators")
        prompt.authenticate(promptInfo)
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
