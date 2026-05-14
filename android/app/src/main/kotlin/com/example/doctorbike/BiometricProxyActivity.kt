package com.nofal.doctorbike

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class BiometricProxyActivity : AppCompatActivity() {
    private var launched = false
    private var finished = false

    private val keyguardLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { activityResult ->
        Log.d(
            "DrBikeBiometric",
            "ProxyActivity keyguard resultCode=${activityResult.resultCode}"
        )
        setResult(
            if (activityResult.resultCode == Activity.RESULT_OK) {
                Activity.RESULT_OK
            } else {
                Activity.RESULT_CANCELED
            }
        )
        Log.d("DrBikeBiometric", "ProxyActivity finish with result")
        finishProxy()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("DrBikeBiometric", "ProxyActivity onCreate")
    }

    override fun onPostResume() {
        super.onPostResume()
        Log.d(
            "DrBikeBiometric",
            "ProxyActivity onPostResume hasFocus=${window?.decorView?.hasWindowFocus()} launched=$launched"
        )
        launchKeyguardWhenReady()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        Log.d("DrBikeBiometric", "ProxyActivity onWindowFocusChanged hasFocus=$hasFocus launched=$launched")
        if (hasFocus) {
            launchKeyguardWhenReady()
        }
    }

    override fun onPause() {
        Log.d("DrBikeBiometric", "ProxyActivity onPause launched=$launched finished=$finished")
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        Log.d("DrBikeBiometric", "ProxyActivity onResume launched=$launched finished=$finished")
    }

    private fun launchKeyguardWhenReady() {
        if (launched || finished) return
        launched = true

        Handler(Looper.getMainLooper()).postDelayed({
            if (finished || isFinishing || isDestroyed) return@postDelayed

            val keyguardManager =
                getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            Log.d(
                "DrBikeBiometric",
                "ProxyActivity preparing keyguard hasFocus=${window?.decorView?.hasWindowFocus()} " +
                    "isDeviceSecure=${keyguardManager.isDeviceSecure}"
            )

            if (!keyguardManager.isDeviceSecure) {
                Log.d("DrBikeBiometric", "ProxyActivity device is not secure")
                setResult(Activity.RESULT_CANCELED)
                finishProxy()
                return@postDelayed
            }

            val intent: Intent? = keyguardManager.createConfirmDeviceCredentialIntent(
                "تأكيد الهوية",
                "استخدم قفل الجهاز لتسجيل الدخول"
            )

            if (intent == null) {
                Log.d("DrBikeBiometric", "ProxyActivity keyguard intent is null")
                setResult(Activity.RESULT_CANCELED)
                finishProxy()
                return@postDelayed
            }

            try {
                Log.d("DrBikeBiometric", "ProxyActivity launching keyguard intent after resume")
                keyguardLauncher.launch(intent)
            } catch (e: Exception) {
                Log.d("DrBikeBiometric", "ProxyActivity launch exception message=${e.message}")
                setResult(Activity.RESULT_CANCELED)
                finishProxy()
            }
        }, 700)
    }

    private fun finishProxy() {
        if (finished) return
        finished = true
        finish()
    }
}
