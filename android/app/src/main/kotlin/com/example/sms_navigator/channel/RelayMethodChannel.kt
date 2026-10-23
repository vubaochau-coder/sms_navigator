package com.example.sms_navigator.channel

import android.content.Context
import com.example.sms_navigator.data.VaultFallbackLog
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.data.RelayChannelSnapshot
import com.example.sms_navigator.data.RelayChannelStore
import com.example.sms_navigator.device.OemAutostartNavigator
import com.example.sms_navigator.policy.WhitelistEntry
import com.example.sms_navigator.policy.WhitelistMode
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import com.example.sms_navigator.worker.RelayWorkScheduler

class RelayMethodChannel(
    messenger: BinaryMessenger,
    private val appContext: Context,
    private val prefs: OtpPreferences,
    private val deviceNavigator: OemAutostartNavigator
) {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val store = RelayChannelStore(prefs)

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getRelayConfig" -> result.success(buildRelayConfig())

                "getWhitelist" -> {
                    val channelId = call.argument<String>("channelId")
                    result.success(buildWhitelist(channelId))
                }

                "setWhitelist" -> handleSetWhitelist(call, result)

                "getRecentLogs" -> result.success(prefs.getRecentLogs())

                // BACKLOG 2.2: lấy rồi xoá báo cáo SecureVault fallback (null nếu không có)
                "takeVaultFallbackReport" -> {
                    val report = VaultFallbackLog.snapshot(prefs.prefs)
                    if (report != null) VaultFallbackLog.clear(prefs.prefs)
                    result.success(report)
                }

                // ---- Multi-channel relay (v2.3) ----
                "setRelayCredentials" -> {
                    val token = call.argument<String>("deviceToken")
                    val baseUrl = call.argument<String>("apiBaseUrl")
                    if (!token.isNullOrBlank()) prefs.deviceToken = token
                    if (!baseUrl.isNullOrBlank()) prefs.apiBaseUrl = baseUrl
                    result.success(true)
                }

                "replaceRelayChannels" -> handleReplaceRelayChannels(call, result)

                "stageRelayKey" -> {
                    val channelId = call.argument<String>("channelId")
                    val epoch = call.argument<Number>("keyEpoch")?.toLong()
                    val key = call.argument<String>("channelKeyBase64")
                    if (channelId.isNullOrBlank() || epoch == null || key.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "channelId, keyEpoch and channelKeyBase64 are required", null)
                    } else {
                        store.stageKey(channelId, call.argument<String>("channelName"), epoch, key)
                        result.success(true)
                    }
                }

                "promoteRelayKey" -> {
                    val channelId = call.argument<String>("channelId")
                    val epoch = call.argument<Number>("keyEpoch")?.toLong()
                    if (channelId.isNullOrBlank() || epoch == null) {
                        result.error("INVALID_ARGS", "channelId and keyEpoch are required", null)
                    } else {
                        result.success(store.promoteKey(channelId, epoch))
                    }
                }

                "discardRelayKey" -> {
                    val channelId = call.argument<String>("channelId")
                    val epoch = call.argument<Number>("keyEpoch")?.toLong()
                    if (channelId.isNullOrBlank() || epoch == null) {
                        result.error("INVALID_ARGS", "channelId and keyEpoch are required", null)
                    } else {
                        store.discardKey(channelId, epoch)
                        result.success(true)
                    }
                }

                "flushParkedMessages" -> {
                    val parked = store.drainParked()
                    var enqueued = 0
                    for (message in parked) {
                        if (store.get(message.channelId) == null) continue // channel gone
                        if (store.get(message.channelId)?.activeKey == null) {
                            store.park(message) // still no key — keep waiting
                            continue
                        }
                        RelayWorkScheduler.enqueue(
                            appContext,
                            message.messageId,
                            message.channelId,
                            message.sender,
                            message.messageText,
                            message.smsId
                        )
                        enqueued++
                    }
                    result.success(enqueued)
                }

                // ---- Legacy single-channel API (kept for older Dart builds) ----
                "setActiveRelayChannel" -> handleSetActiveRelayChannel(call, result)

                "clearActiveRelayChannel" -> {
                    store.replaceAll(emptyList())
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

    private fun buildRelayConfig(): Map<String, Any?> {
        val channels = store.all()
        val first = channels.firstOrNull()
        return mapOf(
            "deviceToken" to prefs.deviceToken,
            "apiBaseUrl" to prefs.apiBaseUrl,
            "parkedCount" to store.parkedCount(),
            // Never expose channel keys over the bridge.
            "channels" to channels.map {
                mapOf(
                    "channelId" to it.channelId,
                    "channelName" to it.name,
                    "activeEpoch" to it.activeEpoch,
                    "pendingEpoch" to it.pendingEpoch,
                    "hasActiveKey" to (it.activeKey != null)
                )
            },
            // Legacy fields (first channel) for older Dart builds.
            "activeChannelId" to first?.channelId,
            "activeChannelName" to first?.name,
            "activeChannelEpoch" to (first?.activeEpoch ?: 1L)
        )
    }

    private fun handleReplaceRelayChannels(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        val raw = call.argument<List<*>>("channels") ?: emptyList<Any>()
        val snapshot = raw.mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val channelId = (map["channelId"] as? String)?.trim()
            val key = map["channelKeyBase64"] as? String
            val epoch = (map["keyEpoch"] as? Number)?.toLong()
            if (channelId.isNullOrBlank() || key.isNullOrBlank() || epoch == null) return@mapNotNull null
            RelayChannelSnapshot(
                channelId = channelId,
                name = (map["channelName"] as? String) ?: "",
                epoch = epoch,
                keyBase64 = key
            )
        }
        val retain = (call.argument<List<*>>("retainChannelIds") ?: emptyList<Any>())
            .mapNotNull { (it as? String)?.takeIf { id -> id.isNotBlank() } }
        store.replaceAll(snapshot, retain)
        result.success(snapshot.size)
    }

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

        if (!deviceToken.isNullOrBlank()) prefs.deviceToken = deviceToken
        if (!apiBaseUrl.isNullOrBlank()) prefs.apiBaseUrl = apiBaseUrl
        val before = store.get(channelId)
        val changed = before?.activeEpoch != keyEpoch || before?.activeKey != channelKeyBase64
        if (changed) {
            store.stageKey(channelId, channelName, keyEpoch, channelKeyBase64)
            store.promoteKey(channelId, keyEpoch)
        }
        result.success(
            mapOf(
                "updated" to changed,
                "activeChannelId" to channelId,
                "epoch" to keyEpoch
            )
        )
    }

    private fun buildWhitelist(channelId: String? = null): Map<String, Any?> {
        val (mode, entries, version) = prefs.getWhitelistConfig(channelId)
        return mapOf(
            "mode" to mode.name,
            "version" to version,
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
        val channelId = call.argument<String>("channelId")
        if (channelId.isNullOrBlank()) {
            result.error("INVALID_ARGS", "channelId is required to set whitelist", null)
            return
        }

        val modeName = call.argument<String>("mode") ?: WhitelistMode.EXPLICIT.name
        val mode = try {
            WhitelistMode.valueOf(modeName)
        } catch (_: Exception) {
            WhitelistMode.EXPLICIT
        }
        val version = (call.argument<Number>("version"))?.toInt() ?: 1

        val rawEntries = call.argument<List<*>>("entries") ?: emptyList<Any>()
        val entries = rawEntries.mapNotNull { item ->
            (item as? Map<*, *>)?.let { map ->
                val address = (map["address"] as? String)?.trim()
                if (address.isNullOrBlank()) {
                    null
                } else {
                    val allowOtp = (map["allowOtp"] as? Boolean)
                        ?: (map["allow_otp"] as? Boolean)
                        ?: false
                    WhitelistEntry(address = address, allowOtp = allowOtp)
                }
            }
        }

        prefs.setWhitelistConfig(channelId, mode, entries, version)
        result.success(true)
    }

    companion object {
        const val CHANNEL = "com.example.sms_navigator/relay"
    }
}
