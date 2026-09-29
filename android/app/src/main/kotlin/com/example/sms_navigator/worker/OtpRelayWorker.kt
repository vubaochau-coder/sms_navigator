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
            put("pair_id", pairId)
            put("device_id", prefs.deviceId)
            put("encrypted_payload", encryptedPayload)
            put("iv", iv)
            put("sent_at", System.currentTimeMillis() / 1000)
            put("ttl_seconds", 300)
        }

        val body = requestJson.toString().toRequestBody("application/json; charset=utf-8".toMediaType())
        val request = Request.Builder()
            .url(relayUrl)
            .post(body)
            .build()

        try {
            val response = httpClient.newCall(request).execute()
            if (response.isSuccessful) {
                Log.i(TAG, "OTP successfully relayed to $relayUrl")
                prefs.addRelayLog(sender, otp, "SUCCESS")
                Result.success()
            } else {
                val errorMsg = "HTTP ${response.code}: ${response.message}"
                Log.w(TAG, "Failed to relay OTP: $errorMsg. Retrying later...")
                prefs.addRelayLog(sender, otp, "RETRYING", errorMsg)
                Result.retry()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Network error during OTP relay: ${e.message}", e)
            prefs.addRelayLog(sender, otp, "RETRYING", e.message)
            Result.retry()
        }
    }

    companion object {
        private const val TAG = "OtpRelayWorker"

        const val KEY_PAIR_ID = "pair_id"
        const val KEY_ENCRYPTED_PAYLOAD = "encrypted_payload"
        const val KEY_IV = "iv"
        const val KEY_SENDER = "sender"
        const val KEY_OTP = "otp"
        const val KEY_RELAY_URL = "relay_url"
    }
}
