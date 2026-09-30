package com.example.sms_navigator.worker

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.sms_navigator.data.OtpPreferences
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.UUID
import java.util.concurrent.TimeUnit

class OtpRelayWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val prefs = OtpPreferences(applicationContext)

        val messageId = inputData.getString(KEY_MESSAGE_ID) ?: UUID.randomUUID().toString()
        val pairId = inputData.getString(KEY_PAIR_ID) ?: prefs.pairId
        val encryptedPayload = inputData.getString(KEY_ENCRYPTED_PAYLOAD)
        val iv = inputData.getString(KEY_IV)
        val sender = inputData.getString(KEY_SENDER) ?: "Unknown"
        val otp = inputData.getString(KEY_OTP) ?: ""
        val relayUrl = inputData.getString(KEY_RELAY_URL) ?: prefs.relayUrl

        if (pairId == null || encryptedPayload == null || iv == null) {
            Log.e(TAG, "Missing required parameters for relay")
            prefs.addRelayLog(sender, otp, "FAILED", "Missing parameters")
            return@withContext Result.failure()
        }

        val requestJson = JSONObject().apply {
            put("message_id", messageId)
            put("pair_id", pairId)
            put("device_id", prefs.deviceId)
            put("encrypted_payload", encryptedPayload)
            put("iv", iv)
            put("sent_at", System.currentTimeMillis() / 1000)
            put("ttl_seconds", 300)
        }

        val body = requestJson.toString().toRequestBody("application/json; charset=utf-8".toMediaType())
        val requestBuilder = Request.Builder()
            .url(relayUrl)
            .post(body)

        val token = prefs.deviceToken
        if (!token.isNullOrBlank()) {
            requestBuilder.addHeader("Authorization", "Bearer $token")
        }

        val request = requestBuilder.build()

        try {
            val response = httpClient.newCall(request).execute()
            if (response.isSuccessful) {
                Log.i(TAG, "OTP successfully relayed to $relayUrl (messageId: $messageId)")
                prefs.addRelayLog(sender, otp, "SUCCESS")
                Result.success()
            } else if (response.code in 400..499) {
                // 4xx client errors (PAYLOAD_EXPIRED, INVALID_SENT_AT, RELAY_PAUSED_BY_SENDER, RECEIVER_NOT_PAIRED, etc.)
                // are permanent/fatal client issues. WorkManager should NOT retry.
                val errorMsg = "HTTP ${response.code}: ${response.message}"
                Log.e(TAG, "Permanent client error relaying OTP ($errorMsg). Dropping.")
                prefs.addRelayLog(sender, otp, "FAILED", errorMsg)
                Result.failure()
            } else {
                // 5xx server errors or other transient HTTP errors -> retry
                val errorMsg = "HTTP ${response.code}: ${response.message}"
                Log.w(TAG, "Transient server error relaying OTP ($errorMsg). Retrying later...")
                prefs.addRelayLog(sender, otp, "RETRYING", errorMsg)
                Result.retry()
            }
        } catch (e: IOException) {
            // Network connectivity / socket timeout errors -> transient, retry
            Log.e(TAG, "Network error during OTP relay: ${e.message}", e)
            prefs.addRelayLog(sender, otp, "RETRYING", e.message)
            Result.retry()
        } catch (e: Exception) {
            // Fatal unexpected exception -> do not retry infinitely
            Log.e(TAG, "Unexpected fatal error during OTP relay: ${e.message}", e)
            prefs.addRelayLog(sender, otp, "FAILED", e.message)
            Result.failure()
        }
    }

    companion object {
        private const val TAG = "OtpRelayWorker"

        const val KEY_MESSAGE_ID = "message_id"
        const val KEY_PAIR_ID = "pair_id"
        const val KEY_ENCRYPTED_PAYLOAD = "encrypted_payload"
        const val KEY_IV = "iv"
        const val KEY_SENDER = "sender"
        const val KEY_OTP = "otp"
        const val KEY_RELAY_URL = "relay_url"
    }
}
