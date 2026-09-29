package com.example.sms_navigator

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.receiver.SmsReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.sms_navigator/relay"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val prefs = OtpPreferences(this)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getRelayConfig" -> {
                    val config = mapOf(
                        "isRelayEnabled" to prefs.isRelayEnabled,
                        "pairId" to prefs.pairId,
                        "sharedSecretBase64" to prefs.sharedSecretBase64,
                        "relayUrl" to prefs.relayUrl,
                        "deviceId" to prefs.deviceId
                    )
                    result.success(config)
                }

                "setRelayConfig" -> {
                    val isEnabled = call.argument<Boolean>("isRelayEnabled")
                    val pairId = call.argument<String>("pairId")
                    val sharedSecretBase64 = call.argument<String>("sharedSecretBase64")
                    val relayUrl = call.argument<String>("relayUrl")

                    if (isEnabled != null) prefs.isRelayEnabled = isEnabled
                    if (pairId != null) prefs.pairId = pairId
                    if (sharedSecretBase64 != null) prefs.sharedSecretBase64 = sharedSecretBase64
                    if (relayUrl != null) prefs.relayUrl = relayUrl

                    result.success(true)
                }

                "getRecentLogs" -> {
                    result.success(prefs.getRecentLogs())
                }

                "clearPairing" -> {
                    prefs.clearPairing()
                    result.success(true)
                }

                "isBatteryOptimizationIgnored" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        pm.isIgnoringBatteryOptimizations(packageName)
                    } else {
                        true
                    }
                    result.success(isIgnoring)
                }

                "requestIgnoreBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INTENT_ERROR", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // Listen for realtime SMS events from SmsReceiver when UI is open
        SmsReceiver.onOtpProcessedListener = { sender, otp ->
            runOnUiThread {
                methodChannel?.invokeMethod("onOtpDetected", mapOf("sender" to sender, "otp" to otp))
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        SmsReceiver.onOtpProcessedListener = null
    }
}
