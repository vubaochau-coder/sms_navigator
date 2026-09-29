package com.example.sms_navigator.data

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest

class OtpPreferences(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    var isRelayEnabled: Boolean
        get() = prefs.getBoolean(KEY_IS_ENABLED, false)
        set(value) = prefs.edit().putBoolean(KEY_IS_ENABLED, value).apply()

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
     * Checks if the sender matches any whitelist entry or prefix.
     * Supports phone number prefixes (+86, 1069, 090...), exact numbers, or Brandnames.
     */
    fun isSenderWhitelisted(sender: String): Boolean {
        if (sender.isBlank()) return false
        val cleanSender = sender.replace(Regex("""[\s\-\(\)]"""), "").lowercase()
        val list = senderWhitelist
        if (list.isEmpty()) return false

        return list.any { rawItem ->
            val cleanItem = rawItem.replace(Regex("""[\s\-\(\)]"""), "").lowercase()
            if (cleanItem.isBlank()) false
            else {
                cleanSender.startsWith(cleanItem) ||
                cleanSender == cleanItem ||
                cleanSender.contains(cleanItem)
            }
        }
    }

    var pairId: String?
        get() = prefs.getString(KEY_PAIR_ID, null)
        set(value) = prefs.edit().putString(KEY_PAIR_ID, value).apply()

    var sharedSecretBase64: String?
        get() = prefs.getString(KEY_SHARED_SECRET, null)
        set(value) = prefs.edit().putString(KEY_SHARED_SECRET, value).apply()

    var relayUrl: String
        get() = prefs.getString(KEY_RELAY_URL, DEFAULT_RELAY_URL) ?: DEFAULT_RELAY_URL
        set(value) = prefs.edit().putString(KEY_RELAY_URL, value).apply()

    var deviceId: String
        get() {
            var id = prefs.getString(KEY_DEVICE_ID, null)
            if (id == null) {
                id = java.util.UUID.randomUUID().toString()
                prefs.edit().putString(KEY_DEVICE_ID, id).apply()
            }
            return id
        }
        set(value) = prefs.edit().putString(KEY_DEVICE_ID, value).apply()

    var deviceToken: String?
        get() = prefs.getString(KEY_DEVICE_TOKEN, null)
        set(value) = prefs.edit().putString(KEY_DEVICE_TOKEN, value).apply()

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

        val item = JSONObject().apply {
            put("id", java.util.UUID.randomUUID().toString())
            put("sender", sender)
            put("otp", otp)
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

    fun clearPairing() {
        prefs.edit()
            .remove(KEY_PAIR_ID)
            .remove(KEY_SHARED_SECRET)
            .putBoolean(KEY_IS_ENABLED, false)
            .apply()
    }

    private fun sha256(input: String): String {
        val md = MessageDigest.getInstance("SHA-256")
        val bytes = md.digest(input.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }

    companion object {
        private const val PREF_NAME = "otp_relay_prefs"
        private const val KEY_IS_ENABLED = "is_relay_enabled"
        private const val KEY_RELAY_MODE = "relay_mode"
        private const val KEY_SENDER_WHITELIST = "sender_whitelist"
        private const val KEY_PAIR_ID = "pair_id"
        private const val KEY_SHARED_SECRET = "shared_secret"
        private const val KEY_RELAY_URL = "relay_url"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_DEVICE_TOKEN = "device_token"
        private const val KEY_RECENT_HASHES = "recent_hashes"
        private const val KEY_RELAY_LOGS = "relay_logs"

        const val MODE_OTP_ONLY = "OTP_ONLY"
        const val MODE_WHITELIST_ALL = "WHITELIST_ALL"
        const val MODE_ALL_SMS = "ALL_SMS"

        const val DEFAULT_RELAY_URL = "https://relay-otp.example.com/api/v1/relay"
    }
}
