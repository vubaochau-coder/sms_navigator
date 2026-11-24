package com.example.sms_navigator.worker

import android.content.SharedPreferences
import android.util.Log
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

/**
 * Đánh thức server Render free-tier từ worker relay — cùng chiến lược với
 * `ServerWaker` bên Dart (lib/core/network/server_waker.dart):
 *
 * 1. Chỉ kích hoạt khi request qua Worker mặc định bị chặn ở edge
 *    ([isEdgeBlocked]): 403/429/503 không mang envelope JSON `success` của server.
 * 2. Chỉ gọi thẳng `GET <render>/health` — không token, không body. SMS vẫn chỉ
 *    gửi qua Worker.
 * 3. Single-flight trong process ([LOCK]) + cooldown [COOLDOWN_MS] lưu trong
 *    SharedPreferences (mỗi job relay là một instance worker riêng): trong
 *    cooldown trả lại kết quả lần trước, không ping thêm.
 * 4. Ping có giới hạn [PING_TIMEOUT_S] giây (cold start ~30–60 s).
 * 5. Thức → caller gửi lại SMS đúng một lần ngay; không thì `Result.retry()`
 *    (backoff của WorkManager). Bị chặn ở edge nghĩa là server chưa nhận gì,
 *    nên gửi lại không tạo bản trùng (server còn có replay guard).
 */
class ServerWakeGate(
    private val prefs: SharedPreferences,
    private val clock: () -> Long = System::currentTimeMillis,
    private val ping: () -> Boolean = { httpPing(DEFAULT_WAKE_URL) },
) {
    /** `true` khi server đã thức. Không bao giờ ném lỗi. */
    fun wake(): Boolean = synchronized(LOCK) {
        val last = prefs.getLong(KEY_LAST_ATTEMPT_AT, 0L)
        val now = clock()
        if (last > 0L && now - last in 0 until COOLDOWN_MS) {
            return prefs.getBoolean(KEY_LAST_RESULT, false)
        }
        val ok = try { ping() } catch (_: Exception) { false }
        prefs.edit()
            .putLong(KEY_LAST_ATTEMPT_AT, clock())
            .putBoolean(KEY_LAST_RESULT, ok)
            .apply()
        ok
    }

    companion object {
        private const val TAG = "ServerWakeGate"
        private val LOCK = Any()

        const val DEFAULT_WAKE_URL = "https://sms-navigator-server.onrender.com/health"
        const val COOLDOWN_MS = 90_000L
        const val PING_TIMEOUT_S = 60L

        private const val KEY_LAST_ATTEMPT_AT = "server_wake_last_attempt_at"
        private const val KEY_LAST_RESULT = "server_wake_last_result"

        private val EDGE_STATUSES = setOf(403, 429, 503)

        /**
         * Request bị chặn trước khi tới server Node: server luôn trả envelope
         * JSON có `success` (kể cả 429 RATE_LIMITED), còn challenge của
         * Cloudflare là HTML và 429 của Render là text thuần.
         */
        fun isEdgeBlocked(code: Int, body: String?): Boolean {
            if (code !in EDGE_STATUSES) return false
            val trimmed = body?.trim().orEmpty()
            val isServerEnvelope = trimmed.startsWith("{") && trimmed.contains("\"success\"")
            return !isServerEnvelope
        }

        private fun httpPing(url: String): Boolean = try {
            doPing(url)
        } catch (e: Exception) {
            Log.w(TAG, "Wake ping failed: ${e.message}")
            false
        }

        private fun doPing(url: String): Boolean {
            val client = OkHttpClient.Builder()
                .connectTimeout(PING_TIMEOUT_S, TimeUnit.SECONDS)
                .readTimeout(PING_TIMEOUT_S, TimeUnit.SECONDS)
                .callTimeout(PING_TIMEOUT_S, TimeUnit.SECONDS)
                .build()
            val request = Request.Builder().url(url).header("Accept", "application/json").get().build()
            client.newCall(request).execute().use { response ->
                val ok = response.code == 200 && response.body?.string().orEmpty().contains("\"healthy\"")
                Log.i(TAG, "Wake ping → HTTP ${response.code} (awake=$ok)")
                return ok
            }
        }
    }
}
