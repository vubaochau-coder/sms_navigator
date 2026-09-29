package com.example.sms_navigator.model

import org.json.JSONObject

data class OtpEvent(
    val sender: String,
    val otp: String,
    val fullMessage: String,
    val timestamp: Long = System.currentTimeMillis()
) {
    fun toJson(): String {
        return JSONObject().apply {
            put("sender", sender)
            put("otp", otp)
            put("fullMessage", fullMessage)
            put("timestamp", timestamp)
        }.toString()
    }

    companion object {
        fun fromJson(jsonStr: String): OtpEvent {
            val json = JSONObject(jsonStr)
            return OtpEvent(
                sender = json.optString("sender", "Unknown"),
                otp = json.optString("otp", ""),
                fullMessage = json.optString("fullMessage", ""),
                timestamp = json.optLong("timestamp", System.currentTimeMillis())
            )
        }
    }
}
