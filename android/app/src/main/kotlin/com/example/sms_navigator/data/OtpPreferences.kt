package com.example.sms_navigator.data

import android.content.Context
import android.content.SharedPreferences
import com.example.sms_navigator.policy.WhitelistEntry
import com.example.sms_navigator.policy.WhitelistMode
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest

class OtpPreferences(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    var relayMode: String
        get() = prefs.getString(KEY_RELAY_MODE, MODE_OTP_ONLY) ?: MODE_OTP_ONLY
        set(value) = prefs.edit().putString(KEY_RELAY_MODE, value).apply()

    var senderWhitelist: List<String>
        get() {
            val raw = prefs.getString(KEY_SENDER_WHITELIST, "[]") ?: "[]"
            return try {
                val array = JSONArray(raw)
                val list = mutableListOf<String>()
                for (i in 0 until array.length()) {
                    val item = array.optString(i)
                    if (item.isNotBlank()) list.add(item.trim())
                }
                list
            } catch (_: Exception) {
                emptyList()
            }
        }
        set(value) {
            val array = JSONArray()
            value.forEach { array.put(it.trim()) }
            prefs.edit().putString(KEY_SENDER_WHITELIST, array.toString()).apply()
        }

    /**
     * Đọc cấu hình white-list v2. Nếu chưa có (lần chạy đầu sau nâng cấp),
     * migrate từ cấu hình legacy (relay_mode + sender_whitelist) một lần duy nhất.
     */
    fun getWhitelistConfig(): Pair<WhitelistMode, List<WhitelistEntry>> {
        val rawMode = prefs.getString(KEY_WHITELIST_MODE, null)
        val rawEntries = prefs.getString(KEY_WHITELIST_ENTRIES, null)
        if (rawMode != null && rawEntries != null) {
            val mode = try {
                WhitelistMode.valueOf(rawMode)
            } catch (_: Exception) {
                WhitelistMode.EXPLICIT
            }
            return mode to parseWhitelistEntries(rawEntries)
        }

        val mode = if (relayMode == MODE_ALL_SMS) WhitelistMode.ALL_ADDRESSES else WhitelistMode.EXPLICIT
        val entries = senderWhitelist.map { WhitelistEntry(address = it, allowOtp = false) }
        setWhitelistConfig(mode, entries)
        return mode to entries
    }

    fun setWhitelistConfig(mode: WhitelistMode, entries: List<WhitelistEntry>) {
        val array = JSONArray()
        entries.forEach { entry ->
            val address = entry.address.trim()
            if (address.isNotBlank()) {
                array.put(
                    JSONObject().apply {
                        put("address", address)
                        put("allow_otp", entry.allowOtp)
                    }
                )
            }
        }
        prefs.edit()
            .putString(KEY_WHITELIST_MODE, mode.name)
            .putString(KEY_WHITELIST_ENTRIES, array.toString())
            .apply()
    }

    private fun parseWhitelistEntries(raw: String): List<WhitelistEntry> {
        return try {
            val array = JSONArray(raw)
            val list = mutableListOf<WhitelistEntry>()
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val address = obj.optString("address").trim()
                if (address.isNotBlank()) {
                    list.add(WhitelistEntry(address = address, allowOtp = obj.optBoolean("allow_otp", false)))
                }
            }
            list
        } catch (_: Exception) {
            emptyList()
        }
    }

    var deviceToken: String?
        get() {
            val stored = prefs.getString(KEY_DEVICE_TOKEN, null) ?: return null
            return try {
                SecureVault.decryptFromBase64(stored)
            } catch (_: Exception) {
                stored
            }
        }
        set(value) {
            if (value == null) {
                prefs.edit().remove(KEY_DEVICE_TOKEN).apply()
                return
            }
            val encrypted = try {
                SecureVault.encryptToBase64(value)
            } catch (_: Exception) {
                value
            }
            prefs.edit().putString(KEY_DEVICE_TOKEN, encrypted).apply()
        }

    var activeChannelId: String?
        get() = prefs.getString(KEY_ACTIVE_CHANNEL_ID, null)
        set(value) = prefs.edit().putString(KEY_ACTIVE_CHANNEL_ID, value).apply()

    var activeChannelName: String?
        get() = prefs.getString(KEY_ACTIVE_CHANNEL_NAME, null)
        set(value) = prefs.edit().putString(KEY_ACTIVE_CHANNEL_NAME, value).apply()

    var activeChannelEpoch: Long
        get() = prefs.getLong(KEY_ACTIVE_CHANNEL_EPOCH, 1L)
        set(value) = prefs.edit().putLong(KEY_ACTIVE_CHANNEL_EPOCH, value).apply()

    var activeChannelKeyBase64: String?
        get() {
            val stored = prefs.getString(KEY_ACTIVE_CHANNEL_KEY, null) ?: return null
            return try {
                SecureVault.decryptFromBase64(stored)
            } catch (_: Exception) {
                stored
            }
        }
        set(value) {
            if (value == null) {
                prefs.edit().remove(KEY_ACTIVE_CHANNEL_KEY).apply()
                return
            }
            val encrypted = try {
                SecureVault.encryptToBase64(value)
            } catch (_: Exception) {
                value
            }
            prefs.edit().putString(KEY_ACTIVE_CHANNEL_KEY, encrypted).apply()
        }

    var apiBaseUrl: String
        get() = prefs.getString(KEY_API_BASE_URL, DEFAULT_API_BASE_URL) ?: DEFAULT_API_BASE_URL
        set(value) {
            val normalized = value.trim().trimEnd('/')
            prefs.edit().putString(KEY_API_BASE_URL, normalized).apply()
        }

    @Synchronized
    fun setActiveRelayChannel(
        channelId: String,
        channelName: String,
        keyEpoch: Long,
        channelKeyBase64: String,
        token: String?,
        baseUrl: String?
    ): Boolean {
        val currentId = activeChannelId
        val currentEpoch = activeChannelEpoch
        val currentKey = activeChannelKeyBase64
        if (currentId == channelId && currentEpoch == keyEpoch && currentKey == channelKeyBase64 && !token.isNullOrBlank()) {
            if (!baseUrl.isNullOrBlank()) apiBaseUrl = baseUrl
            deviceToken = token
            return false
        }

        activeChannelId = channelId
        activeChannelName = channelName
        activeChannelEpoch = keyEpoch
        activeChannelKeyBase64 = channelKeyBase64
        if (!token.isNullOrBlank()) deviceToken = token
        if (!baseUrl.isNullOrBlank()) apiBaseUrl = baseUrl
        return true
    }

    @Synchronized
    fun clearActiveRelayChannel() {
        prefs.edit()
            .remove(KEY_ACTIVE_CHANNEL_ID)
            .remove(KEY_ACTIVE_CHANNEL_NAME)
            .remove(KEY_ACTIVE_CHANNEL_EPOCH)
            .remove(KEY_ACTIVE_CHANNEL_KEY)
            .apply()
    }

    /**
     * Checks if this OTP was already sent in the last 5 minutes (TTL / Deduplication).
     * If not duplicate, records it and returns false.
     */
    @Synchronized
    fun isDuplicateAndRecord(sender: String, otp: String): Boolean {
        val now = System.currentTimeMillis()
        val window = 5 * 60 * 1000L // 5 minutes
        val hash = sha256("$sender:$otp")

        // Format in Prefs: hash -> timestamp
        val rawJson = prefs.getString(KEY_RECENT_HASHES, "{}") ?: "{}"
        val json = JSONObject(rawJson)

        // Clean up old entries
        val cleanJson = JSONObject()
        val keys = json.keys()
        while (keys.hasNext()) {
            val k = keys.next()
            val time = json.optLong(k, 0L)
            if (now - time < window) {
                cleanJson.put(k, time)
            }
        }

        if (cleanJson.has(hash)) {
            return true // Duplicate found
        }

        // Record new hash
        cleanJson.put(hash, now)
        prefs.edit().putString(KEY_RECENT_HASHES, cleanJson.toString()).apply()
        return false
    }

    /**
     * Records a relay activity log.
     */
    @Synchronized
    fun addRelayLog(sender: String, otp: String, status: String, error: String? = null) {
        val logsJsonStr = prefs.getString(KEY_RELAY_LOGS, "[]") ?: "[]"
        val jsonArray = JSONArray(logsJsonStr)

        val maskedOtp = if (otp == "SMS" || otp.isEmpty()) otp else if (otp.length > 2) otp.take(1) + "***" + otp.takeLast(1) else "***"

        val item = JSONObject().apply {
            put("id", java.util.UUID.randomUUID().toString())
            put("sender", sender)
            put("otp", maskedOtp)
            put("status", status)
            put("error", error ?: "")
            put("timestamp", System.currentTimeMillis())
        }

        // Prepend new item
        val newArray = JSONArray()
        newArray.put(item)
        for (i in 0 until minOf(jsonArray.length(), 29)) {
            newArray.put(jsonArray.get(i))
        }

        prefs.edit().putString(KEY_RELAY_LOGS, newArray.toString()).apply()
    }

    fun getRecentLogs(): String {
        return prefs.getString(KEY_RELAY_LOGS, "[]") ?: "[]"
    }

    private fun sha256(input: String): String {
        val md = MessageDigest.getInstance("SHA-256")
        val bytes = md.digest(input.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }

    companion object {
        private const val PREF_NAME = "otp_relay_prefs"
        private const val KEY_RELAY_MODE = "relay_mode"
        private const val KEY_SENDER_WHITELIST = "sender_whitelist"
        private const val KEY_WHITELIST_MODE = "whitelist_v2_mode"
        private const val KEY_WHITELIST_ENTRIES = "whitelist_v2_entries"
        private const val KEY_DEVICE_TOKEN = "device_token"
        private const val KEY_RECENT_HASHES = "recent_hashes"
        private const val KEY_RELAY_LOGS = "relay_logs"
        private const val KEY_ACTIVE_CHANNEL_ID = "active_channel_id"
        private const val KEY_ACTIVE_CHANNEL_NAME = "active_channel_name"
        private const val KEY_ACTIVE_CHANNEL_EPOCH = "active_channel_epoch"
        private const val KEY_ACTIVE_CHANNEL_KEY = "active_channel_key"
        private const val KEY_API_BASE_URL = "api_base_url"

        const val MODE_OTP_ONLY = "OTP_ONLY"
        const val MODE_WHITELIST_ALL = "WHITELIST_ALL"
        const val MODE_ALL_SMS = "ALL_SMS"

        const val DEFAULT_API_BASE_URL = "https://sms-navigator-server.onrender.com"
    }
}
