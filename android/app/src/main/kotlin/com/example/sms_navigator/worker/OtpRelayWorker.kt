package com.example.sms_navigator.worker

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.data.ParkedMessage
import com.example.sms_navigator.data.RelayChannelStore
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

    private data class SendResult(val code: Int, val message: String, val body: String?)

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val prefs = OtpPreferences(applicationContext)
        val store = RelayChannelStore(prefs)
        val outboxId = inputData.getString(KEY_OUTBOX_ID)
        val queued = outboxId?.let { store.getOutbox(it) }

        val result = relay(prefs, store, queued)

        // Chỉ giữ nội dung khi còn retry; xong (gửi được / bỏ / đã park) thì xoá.
        if (outboxId != null && result !is Result.Retry) store.removeOutbox(outboxId)
        result
    }

    private fun relay(prefs: OtpPreferences, store: RelayChannelStore, queued: ParkedMessage?): Result {
        val messageId = queued?.messageId?.takeIf { it.isNotBlank() }
            ?: inputData.getString(KEY_MESSAGE_ID) ?: UUID.randomUUID().toString()
        val channelId = inputData.getString(KEY_CHANNEL_ID) ?: queued?.channelId
        // Legacy: job enqueue bởi bản cũ vẫn mang text/sender trong inputData.
        val messageText = queued?.messageText ?: inputData.getString(KEY_MESSAGE_TEXT)
        val sender = queued?.sender?.takeIf { it.isNotBlank() } ?: inputData.getString(KEY_SENDER) ?: "Unknown"
        val token = prefs.deviceToken
        val baseUrl = prefs.apiBaseUrl.trimEnd('/')
        val relayUrl = "$baseUrl/api/v2/channels/messages"
        val smsId = queued?.smsId.orEmpty()
        var channelLabel: String? = null
        fun log(status: String, detail: String?) = prefs.addRelayLog(
            sender, "", status, detail,
            smsId = smsId, channelId = channelId, channelName = channelLabel
        )

        if (channelId.isNullOrBlank() || messageText.isNullOrEmpty() || token.isNullOrBlank()) {
            val missing = buildList {
                if (channelId.isNullOrBlank()) add("channelId")
                if (messageText.isNullOrEmpty()) add("messageText")
                if (token.isNullOrBlank()) add("token")
            }.joinToString(", ")
            Log.e(TAG, "Missing required parameters for V2 relay: $missing")
            log("FAILED", "Missing config: $missing")
            return Result.failure()
        }

        // Key + epoch are read at run time (not captured at enqueue) so a
        // rotation that happened after the SMS arrived is picked up.
        val channel = store.get(channelId)
        if (channel == null) {
            Log.w(TAG, "Channel $channelId is no longer relayed. Dropping messageId=$messageId.")
            log("FAILED", "Kênh không còn được relay")
            return Result.failure()
        }
        val label = channel.name.ifBlank { channelId }
        channelLabel = label
        val parked = ParkedMessage(messageId, channelId, sender, messageText, System.currentTimeMillis(), smsId)

        val activeKey = channel.activeKey
        if (activeKey == null) {
            store.park(parked)
            log("PARKED", "[$label] Chưa có khóa kênh — mở app để đồng bộ")
            return Result.success()
        }

        // Cap total retries so transient 5xx/network failures never retry forever.
        if (runAttemptCount > MAX_RETRY_ATTEMPTS) {
            Log.e(TAG, "Exceeded max retry attempts ($MAX_RETRY_ATTEMPTS) for messageId=$messageId. Dropping.")
            log("FAILED", "Max retry attempts exceeded")
            return Result.failure()
        }

        val payloadToEncrypt = JSONObject().apply {
            put("sender", sender)
            put("fullMessage", messageText)
        }.toString()

        var epoch = channel.activeEpoch
        var key: String = activeKey
        var healedOnce = false

        while (true) {
            val result = try {
                send(relayUrl, token, channelId, epoch, key, payloadToEncrypt)
            } catch (e: IOException) {
                Log.e(TAG, "Network error during relay: ${e.message}", e)
                log("RETRYING", e.message)
                return Result.retry()
            } catch (e: Exception) {
                Log.e(TAG, "Relay failed for messageId=$messageId: ${e.message}", e)
                log("FAILED", "Crypto/IO error: ${e.message}")
                return Result.failure()
            }

            when {
                result.code in 200..299 -> {
                    Log.i(TAG, "Message relayed to V2 channel $channelId (epoch $epoch)")
                    log("SUCCESS", "Kênh: $label (epoch $epoch)")
                    return Result.success()
                }

                result.code == 409 -> {
                    val body = parseJson(result.body)
                    val errorCode = body?.optString("error").orEmpty()
                    if (errorCode == "REPLAY_DETECTED") {
                        // A previous attempt already landed (response lost) — done.
                        log("SUCCESS", "Kênh: $label (đã nhận trước đó)")
                        return Result.success()
                    }
                    if (errorCode == "EPOCH_OUTDATED") {
                        val serverEpoch = body?.optLong("current_epoch", 0L) ?: 0L
                        val stagedKey = if (serverEpoch > 0) store.get(channelId)?.keyFor(serverEpoch) else null
                        if (!healedOnce && stagedKey != null) {
                            // The rotation committed but the app never promoted
                            // (killed / offline): we already hold the staged key.
                            store.promoteKey(channelId, serverEpoch)
                            Log.i(TAG, "Self-healed epoch $epoch → $serverEpoch for $channelId, resending")
                            epoch = serverEpoch
                            key = stagedKey
                            healedOnce = true
                            continue
                        }
                        store.park(parked)
                        Log.w(TAG, "No key for server epoch $serverEpoch on $channelId. Parked messageId=$messageId.")
                        log("PARKED", "[$label] Khóa kênh đã đổi — mở app để đồng bộ")
                        return Result.success()
                    }
                    val errorMsg = "HTTP 409 ${errorCode.ifBlank { result.message }}"
                    log("FAILED", errorMsg)
                    return Result.failure()
                }

                result.code == 401 -> {
                    // Device token hết hạn / bị thay (BACKLOG 3.2): app đăng ký lại
                    // khi mở và đẩy token mới xuống — giữ SMS lại để gửi sau.
                    store.park(parked)
                    Log.w(TAG, "Device token rejected (401). Parked messageId=$messageId until the app re-registers.")
                    log("PARKED", "[$label] Phiên thiết bị hết hạn — mở app để đăng ký lại")
                    return Result.success()
                }

                result.code in 400..499 -> {
                    val errorMsg = "HTTP ${result.code}: ${result.message}"
                    Log.e(TAG, "Permanent client error relaying to V2 ($errorMsg). Dropping.")
                    log("FAILED", errorMsg)
                    return Result.failure()
                }

                else -> {
                    val errorMsg = "HTTP ${result.code}: ${result.message}"
                    Log.w(TAG, "Transient server error relaying ($errorMsg). Retrying...")
                    log("RETRYING", errorMsg)
                    return Result.retry()
                }
            }
        }
        // Every branch of the loop above returns; never reached.
        return Result.failure()
    }

    private fun send(
        relayUrl: String,
        token: String,
        channelId: String,
        epoch: Long,
        channelKeyBase64: String,
        payload: String
    ): SendResult {
        val encrypted = com.example.sms_navigator.crypto.ChannelCryptoNative.encryptMessage(
            plaintext = payload,
            channelKeyBase64 = channelKeyBase64,
            channelId = channelId,
            keyEpoch = epoch,
            sequenceHint = 0L
        )
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
        httpClient.newCall(request).execute().use { response ->
            return SendResult(response.code, response.message, response.body?.string())
        }
    }

    private fun parseJson(raw: String?): JSONObject? =
        try { if (raw.isNullOrBlank()) null else JSONObject(raw) } catch (_: Exception) { null }

    companion object {
        private const val TAG = "OtpRelayWorker"

        const val MAX_RETRY_ATTEMPTS = 5

        const val KEY_MESSAGE_ID = "message_id"
        const val KEY_CHANNEL_ID = "channel_id"
        /** Legacy (≤ v2.2): epoch captured at enqueue. Ignored — epoch is read from RelayChannelStore. */
        const val KEY_CHANNEL_EPOCH = "channel_epoch"
        /** Id trong outbox mã hoá của RelayChannelStore (2.1). */
        const val KEY_OUTBOX_ID = "outbox_id"
        /** Legacy (≤ 21/10/2026): nội dung SMS nằm thẳng trong inputData. Chỉ còn đọc để xử lý job cũ. */
        const val KEY_MESSAGE_TEXT = "message_text"
        /** Legacy — xem [KEY_MESSAGE_TEXT]. */
        const val KEY_SENDER = "sender"
        /** Legacy: base URL captured at enqueue. Ignored — read from OtpPreferences at run time. */
        const val KEY_API_BASE_URL = "api_base_url"
    }
}
