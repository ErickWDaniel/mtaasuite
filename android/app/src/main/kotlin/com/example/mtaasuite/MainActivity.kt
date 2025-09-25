package tz.co.mtaasuite.mtaasuite

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.recaptcha.Recaptcha
import com.google.android.recaptcha.RecaptchaAction
import com.google.android.recaptcha.RecaptchaClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val CHANNEL = "tz.co.mtaasuite.mtaasuite/recaptcha"
    private lateinit var recaptchaClient: RecaptchaClient
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize reCAPTCHA Enterprise client
        initializeRecaptcha()
        
        // Set up method channel for Flutter communication
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "executeRecaptcha" -> {
                    val action = call.argument<String>("action") ?: "LOGIN"
                    executeRecaptcha(action, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initializeRecaptcha() {
        try {
            Log.d(TAG, "=== RECAPTCHA ENTERPRISE INITIALIZATION START ===")
            CoroutineScope(Dispatchers.Main).launch {
                try {
                    Log.d(TAG, "About to call Recaptcha.getClient() - checking return type...")
                    val clientResult = Recaptcha.getClient(
                        application,
                        "6LeMlsErAAAAAJMZkGTtEvOvjoTFFzW4peW9E69m" // Your site key
                    )
                    Log.d(TAG, "Recaptcha.getClient() returned type: ${clientResult::class.java.name}")
                    Log.d(TAG, "Result success status: ${clientResult.isSuccess}")
                    
                    recaptchaClient = clientResult.getOrThrow()
                    Log.d(TAG, "reCAPTCHA Enterprise client initialized successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to initialize reCAPTCHA Enterprise client: ${e.message}")
                }
            }
            Log.d(TAG, "=== RECAPTCHA ENTERPRISE INITIALIZATION END ===")
        } catch (e: Exception) {
            Log.e(TAG, "reCAPTCHA initialization exception: ${e.message}")
        }
    }

    private fun executeRecaptcha(action: String, result: MethodChannel.Result) {
        if (!::recaptchaClient.isInitialized) {
            Log.e(TAG, "reCAPTCHA client not initialized")
            result.error("RECAPTCHA_ERROR", "reCAPTCHA client not initialized", null)
            return
        }

        Log.d(TAG, "=== EXECUTING RECAPTCHA ACTION: $action ===")
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val recaptchaAction = RecaptchaAction.custom(action)
                val token = recaptchaClient.execute(recaptchaAction)
                
                Log.d(TAG, "reCAPTCHA token generated successfully for action: $action")
                CoroutineScope(Dispatchers.Main).launch {
                    result.success(token)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to execute reCAPTCHA: ${e.message}")
                CoroutineScope(Dispatchers.Main).launch {
                    result.error("RECAPTCHA_ERROR", "Failed to execute reCAPTCHA: ${e.message}", null)
                }
            }
        }
    }
}
