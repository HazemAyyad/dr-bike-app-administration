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
    private val authenticators =
        BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.BIOMETRIC_WEAK or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(checkAvailability())
                    "authenticate" -> authenticate(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkAvailability(): Map<String, Any> {
        val code = BiometricManager.from(this).canAuthenticate(authenticators)
        return mapOf(
            "available" to (code == BiometricManager.BIOMETRIC_SUCCESS),
            "code" to code,
            "message" to messageForCode(code),
        )
    }

    private fun authenticate(result: MethodChannel.Result) {
        val availability = checkAvailability()
        if (availability["available"] != true) {
            result.success(
                mapOf(
                    "success" to false,
                    "available" to false,
                    "code" to availability["code"],
                    "message" to availability["message"],
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
                    Log.d("DrBikeBiometric", "Native authentication succeeded")
                    if (completed.compareAndSet(false, true)) {
                        result.success(
                            mapOf(
                                "success" to true,
                                "available" to true,
                                "code" to 0,
                                "message" to "تم التحقق بنجاح",
                            )
                        )
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    Log.d("DrBikeBiometric", "Native authentication error: code=$errorCode message=$errString")
                    if (completed.compareAndSet(false, true)) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "available" to true,
                                "code" to errorCode,
                                "message" to errString.toString(),
                            )
                        )
                    }
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    Log.d("DrBikeBiometric", "Native authentication failed; allowing retry")
                }
            },
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("تأكيد الهوية")
            .setSubtitle("استخدم البصمة أو قفل الجهاز لتسجيل الدخول")
            .setAllowedAuthenticators(authenticators)
            .build()

        Log.d("DrBikeBiometric", "Showing native biometric prompt")
        prompt.authenticate(promptInfo)
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
