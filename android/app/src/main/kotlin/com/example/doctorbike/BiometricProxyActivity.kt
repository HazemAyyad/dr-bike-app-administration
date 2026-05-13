package com.nofal.doctorbike

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.os.Bundle
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class BiometricProxyActivity : AppCompatActivity() {
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
        finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("DrBikeBiometric", "ProxyActivity onCreate")

        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguardManager.isDeviceSecure) {
            Log.d("DrBikeBiometric", "ProxyActivity device is not secure")
            setResult(Activity.RESULT_CANCELED)
            finish()
            return
        }

        val intent = keyguardManager.createConfirmDeviceCredentialIntent(
            "تأكيد الهوية",
            "استخدم قفل الجهاز لتسجيل الدخول"
        )

        if (intent == null) {
            Log.d("DrBikeBiometric", "ProxyActivity keyguard intent is null")
            setResult(Activity.RESULT_CANCELED)
            finish()
            return
        }

        Log.d("DrBikeBiometric", "ProxyActivity launching keyguard intent")
        keyguardLauncher.launch(intent)
    }
}
