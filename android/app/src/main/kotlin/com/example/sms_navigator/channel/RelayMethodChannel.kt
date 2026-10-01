package com.example.sms_navigator.channel

import android.os.Handler
import android.os.Looper
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.device.OemAutostartNavigator
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class RelayMethodChannel(
    messenger: BinaryMessenger,
    private val prefs: OtpPreferences,
    private val deviceNavigator: OemAutostartNavigator
) {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getRelayConfig" -> result.success(buildRelayConfig())

                "setRelayConfig" -> handleSetRelayConfig(call, result)

                "getRecentLogs" -> result.success(prefs.getRecentLogs())

                "clearPairing" -> {
                    prefs.clearPairing()
                    result.success(true)
                }

                "isAggressiveBatteryRom" -> {
                    val oem = deviceNavigator.detectAggressiveOem()
                    result.success(
                        mapOf(
                            "isAggressive" to (oem != null),
                            "oem" to oem
                        )
                    )
                }

                "getDeviceName" -> {
                    result.success(deviceNavigator.getDeviceDisplayName())
                }

                "openAutostartSettings" -> {
                    val opened = deviceNavigator.openAutostartSettings()
                    if (!opened) {
                        deviceNavigator.openAppDetailsSettings()
                    }
                    result.success(opened)
                }

                "isBatteryOptimizationIgnored" -> {
                    result.success(deviceNavigator.isBatteryOptimizationIgnored())
                }

                "requestIgnoreBatteryOptimization" -> {
                    try {
                        deviceNavigator.requestIgnoreBatteryOptimization()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    fun unregister() {
        channel.setMethodCallHandler(null)
    }

    fun notifyOtpDetected(sender: String, otp: String) {
        mainHandler.post {
            channel.invokeMethod(
                "onOtpDetected",
                mapOf("sender" to sender, "otp" to otp)
            )
        }
    }

    private fun buildRelayConfig(): Map<String, Any?> = mapOf(
        "isRelayEnabled" to prefs.isRelayEnabled,
        "relayMode" to prefs.relayMode,
        "senderWhitelist" to prefs.senderWhitelist,
        "pairId" to prefs.pairId,
        "sharedSecretBase64" to prefs.sharedSecretBase64,
        "relayUrl" to prefs.relayUrl,
        "deviceId" to prefs.deviceId,
        "deviceToken" to prefs.deviceToken
    )

    private fun handleSetRelayConfig(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        val isEnabled = call.argument<Boolean>("isRelayEnabled")
        val relayMode = call.argument<String>("relayMode")
        val senderWhitelist = call.argument<List<String>>("senderWhitelist")
        val pairId = call.argument<String>("pairId")
        val sharedSecretBase64 = call.argument<String>("sharedSecretBase64")
        val relayUrl = call.argument<String>("relayUrl")
        val deviceToken = call.argument<String>("deviceToken")
        val deviceId = call.argument<String>("deviceId")

        if (isEnabled != null) prefs.isRelayEnabled = isEnabled
        if (relayMode != null) prefs.relayMode = relayMode
        if (senderWhitelist != null) prefs.senderWhitelist = senderWhitelist
        if (pairId != null) prefs.pairId = pairId
        if (sharedSecretBase64 != null) prefs.sharedSecretBase64 = sharedSecretBase64
        if (relayUrl != null) prefs.relayUrl = relayUrl
        if (deviceToken != null) prefs.deviceToken = deviceToken
        if (deviceId != null) prefs.deviceId = deviceId

        result.success(true)
    }

    companion object {
        const val CHANNEL = "com.example.sms_navigator/relay"
    }
}
