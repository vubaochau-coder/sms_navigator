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
        val channelId = inputData.getString(KEY_CHANNEL_ID) ?: prefs.activeChannelId
        val epoch = inputData.getLong(KEY_CHANNEL_EPOCH, prefs.activeChannelEpoch)
        val messageText = inputData.getString(KEY_MESSAGE_TEXT)
        val sender = inputData.getString(KEY_SENDER) ?: "Unknown"
        val channelKeyBase64 = prefs.activeChannelKeyBase64
        val token = prefs.deviceToken
        val baseUrl = (inputData.getString(KEY_API_BASE_URL) ?: prefs.apiBaseUrl).trimEnd('/')
        val relayUrl = "$baseUrl/api/v2/channels/messages"

        if (channelId.isNullOrBlank() || channelKeyBase64.isNullOrBlank() || messageText.isNullOrEmpty() || token.isNullOrBlank()) {
            val missing = buildList {
                if (channelId.isNullOrBlank()) add("channelId")
                if (channelKeyBase64.isNullOrBlank()) add("channelKey")
                if (messageText.isNullOrEmpty()) add("messageText")
                if (token.isNullOrBlank()) add("token")
            }.joinToString(", ")
            Log.e(TAG, "Missing required parameters for V2 relay: $missing")
            prefs.addRelayLog(sender, "", "FAILED", "Missing config: $missing")
            return@withContext Result.failure()
        }

        // Cap total retries so transient 5xx/network failures never retry forever.
        if (runAttemptCount > MAX_RETRY_ATTEMPTS) {
            Log.e(TAG, "Exceeded max retry attempts ($MAX_RETRY_ATTEMPTS) for messageId=$messageId. Dropping.")
            prefs.addRelayLog(sender, "", "FAILED", "Max retry attempts exceeded")
            return@withContext Result.failure()
        }

        val encrypted = try {
            com.example.sms_navigator.crypto.ChannelCryptoNative.encryptMessage(
                plaintext = messageText,
                channelKeyBase64 = channelKeyBase64,
                channelId = channelId,
                keyEpoch = epoch,
                sequenceHint = 0L
            )
        } catch (e: Exception) {
            Log.e(TAG, "Encryption failed for messageId=$messageId: ${e.message}", e)
            prefs.addRelayLog(sender, "", "FAILED", "Crypto error: ${e.message}")
            return@withContext Result.failure()
        }

        val requestJson = JSONObject().apply {
            put("channel_id", channelId)
            put("request_epoch", epoch)
            put("ciphertext", encrypted.ciphertextBase64)
            put("nonce", encrypted.nonceBase64)
        }

        val body = requestJson.toString().toRequestBody("application/json; charset=utf-8".toMediaType())
        val request = Request.Builder()
            .url(relayUrl)
            .addHeader("Authorization", "Bearer $token")
            .post(body)
            .build()

        try {
            val response = httpClient.newCall(request).execute()
            val channelLabel = prefs.activeChannelName ?: channelId
            if (response.isSuccessful) {
                Log.i(TAG, "Message successfully relayed to V2 channel $channelId (epoch $epoch)")
                prefs.addRelayLog(sender, "", "SUCCESS", "Kênh: $channelLabel (epoch $epoch)")
                Result.success()
            } else if (response.code in 400..499) {
                val errorMsg = "HTTP ${response.code}: ${response.message}"
                val extraHint = if (response.code == 409) " (Lỗi epoch/replay - mở app đồng bộ)" else ""
                Log.e(TAG, "Permanent client error relaying to V2 ($errorMsg$extraHint). Dropping.")
                prefs.addRelayLog(sender, "", "FAILED", "$errorMsg$extraHint")
                Result.failure()
            } else {
                val errorMsg = "HTTP ${response.code}: ${response.message}"
                Log.w(TAG, "Transient server error relaying ($errorMsg). Retrying...")
                prefs.addRelayLog(sender, "", "RETRYING", errorMsg)
                Result.retry()
            }
        } catch (e: IOException) {
            Log.e(TAG, "Network error during relay: ${e.message}", e)
            prefs.addRelayLog(sender, "", "RETRYING", e.message)
            Result.retry()
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during relay: ${e.message}", e)
            prefs.addRelayLog(sender, "", "FAILED", e.message)
            Result.failure()
        }
    }

    companion object {
        private const val TAG = "OtpRelayWorker"

        const val MAX_RETRY_ATTEMPTS = 5

        const val KEY_MESSAGE_ID = "message_id"
        const val KEY_CHANNEL_ID = "channel_id"
        const val KEY_CHANNEL_EPOCH = "channel_epoch"
        const val KEY_MESSAGE_TEXT = "message_text"
        const val KEY_SENDER = "sender"
        const val KEY_API_BASE_URL = "api_base_url"
    }
}
