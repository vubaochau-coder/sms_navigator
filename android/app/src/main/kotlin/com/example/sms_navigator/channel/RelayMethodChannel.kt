package com.example.sms_navigator.channel

import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.device.OemAutostartNavigator
import com.example.sms_navigator.policy.WhitelistEntry
import com.example.sms_navigator.policy.WhitelistMode
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class RelayMethodChannel(
    messenger: BinaryMessenger,
    private val prefs: OtpPreferences,
    private val deviceNavigator: OemAutostartNavigator
) {

    private val channel = MethodChannel(messenger, CHANNEL)

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getRelayConfig" -> result.success(buildRelayConfig())

                "getWhitelist" -> result.success(buildWhitelist())

                "setWhitelist" -> handleSetWhitelist(call, result)

                "getRecentLogs" -> result.success(prefs.getRecentLogs())

                "setActiveRelayChannel" -> handleSetActiveRelayChannel(call, result)

                "clearActiveRelayChannel" -> {
                    prefs.clearActiveRelayChannel()
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

    private fun buildRelayConfig(): Map<String, Any?> = mapOf(
        "deviceToken" to prefs.deviceToken,
        "activeChannelId" to prefs.activeChannelId,
        "activeChannelName" to prefs.activeChannelName,
        "activeChannelEpoch" to prefs.activeChannelEpoch,
        "apiBaseUrl" to prefs.apiBaseUrl
    )

    @Synchronized
    private fun handleSetActiveRelayChannel(
        call: io.flutter.plugin.common.MethodCall,
        result: io.flutter.plugin.common.MethodChannel.Result
    ) {
        val channelId = call.argument<String>("channelId")
        val channelName = call.argument<String>("channelName") ?: ""
        val keyEpoch = (call.argument<Number>("keyEpoch"))?.toLong() ?: 1L
        val channelKeyBase64 = call.argument<String>("channelKeyBase64")
        val deviceToken = call.argument<String>("deviceToken")
        val apiBaseUrl = call.argument<String>("apiBaseUrl")

        if (channelId.isNullOrBlank() || channelKeyBase64.isNullOrBlank()) {
            result.error("INVALID_ARGS", "channelId and channelKeyBase64 are required", null)
            return
        }

        val changed = prefs.setActiveRelayChannel(
            channelId = channelId,
            channelName = channelName,
            keyEpoch = keyEpoch,
            channelKeyBase64 = channelKeyBase64,
            token = deviceToken,
            baseUrl = apiBaseUrl
        )
        result.success(
            mapOf(
                "updated" to changed,
                "activeChannelId" to channelId,
                "epoch" to keyEpoch
            )
        )
    }

    private fun buildWhitelist(): Map<String, Any?> {
        val (mode, entries) = prefs.getWhitelistConfig()
        return mapOf(
            "mode" to mode.name,
            "entries" to entries.map {
                mapOf(
                    "address" to it.address,
                    "allowOtp" to it.allowOtp
                )
            }
        )
    }

    private fun handleSetWhitelist(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        val modeName = call.argument<String>("mode") ?: WhitelistMode.EXPLICIT.name
        val mode = try {
            WhitelistMode.valueOf(modeName)
        } catch (_: Exception) {
            WhitelistMode.EXPLICIT
        }

        val rawEntries = call.argument<List<*>>("entries") ?: emptyList<Any>()
        val entries = rawEntries.mapNotNull { item ->
            (item as? Map<*, *>)?.let { map ->
                val address = (map["address"] as? String)?.trim()
                if (address.isNullOrBlank()) {
                    null
                } else {
                    WhitelistEntry(address = address, allowOtp = map["allowOtp"] == true)
                }
            }
        }

        prefs.setWhitelistConfig(mode, entries)
        result.success(true)
    }

    companion object {
        const val CHANNEL = "com.example.sms_navigator/relay"
    }
}
