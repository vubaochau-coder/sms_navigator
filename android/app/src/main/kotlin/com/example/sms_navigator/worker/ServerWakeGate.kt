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
 * 3. Polling có giãn cách ([POLL_DELAYS_MS]) tới khi `/health` trả healthy
 *    hoặc hết [WAKE_DEADLINE_MS]: hibernation gate của Render trả 429 ngay
 *    trong suốt ~1 phút khởi động thay vì giữ request lại như trước.
 * 4. Single-flight trong process ([LOCK]) + cooldown lưu trong
 *    SharedPreferences (mỗi job relay là một instance worker riêng): thành công
 *    → [SUCCESS_COOLDOWN_MS], thất bại → [FAILURE_COOLDOWN_MS]; trong cooldown
 *    trả lại kết quả lần trước, không ping thêm.
 * 5. Thức → caller gửi lại SMS đúng một lần ngay; không thì `Result.retry()`
 *    (backoff của WorkManager). Bị chặn ở edge nghĩa là server chưa nhận gì,
 *    nên gửi lại không tạo bản trùng (server còn có replay guard).
 */
class ServerWakeGate(
    private val prefs: SharedPreferences,
    private val clock: () -> Long = System::currentTimeMillis,
    private val ping: () -> Boolean = { httpPing(DEFAULT_WAKE_URL) },
    private val sleep: (Long) -> Unit = { Thread.sleep(it) },
) {
    /** `true` khi server đã thức. Không bao giờ ném lỗi. */
    fun wake(): Boolean = synchronized(LOCK) {
        val last = prefs.getLong(KEY_LAST_ATTEMPT_AT, 0L)
        val lastResult = prefs.getBoolean(KEY_LAST_RESULT, false)
        val cooldown = if (lastResult) SUCCESS_COOLDOWN_MS else FAILURE_COOLDOWN_MS
        if (last > 0L && clock() - last in 0 until cooldown) {
            return lastResult
        }
        val ok = poll()
        prefs.edit()
            .putLong(KEY_LAST_ATTEMPT_AT, clock())
            .putBoolean(KEY_LAST_RESULT, ok)
            .apply()
        ok
    }

    private fun poll(): Boolean {
        val started = clock()
        var attempt = 0
        while (true) {
            if (try { ping() } catch (_: Exception) { false }) return true
            val delay = POLL_DELAYS_MS[minOf(attempt, POLL_DELAYS_MS.size - 1)]
            attempt++
            if (clock() - started + delay >= WAKE_DEADLINE_MS) return false
            try { sleep(delay) } catch (_: InterruptedException) { return false }
        }
    }

    companion object {
        private const val TAG = "ServerWakeGate"
        private val LOCK = Any()

        const val DEFAULT_WAKE_URL = "https://sms-navigator-server.onrender.com/health"
        const val WAKE_DEADLINE_MS = 150_000L
        val POLL_DELAYS_MS = longArrayOf(3_000L, 5_000L, 8_000L, 10_000L)
        const val SUCCESS_COOLDOWN_MS = 60_000L
        const val FAILURE_COOLDOWN_MS = 30_000L
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
