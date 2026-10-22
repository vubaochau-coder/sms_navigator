package com.example.sms_navigator.data

import android.content.SharedPreferences
import android.util.Log

/**
 * Ghi lại mỗi lần [SecureVault] lỗi và dữ liệu nhạy cảm phải lưu **thô**
 * (BACKLOG 2.2). Chính sách vẫn là fail-open — một số ROM có Android Keystore
 * chập chờn, fail-closed sẽ làm dừng hẳn relay — nhưng không còn im lặng:
 * Dart đọc báo cáo này lúc khởi động, gửi Crashlytics (non-fatal) + cảnh báo
 * người dùng, rồi xoá. Lần ghi kế tiếp tự mã hoá lại nếu Keystore đã ổn.
 */
object VaultFallbackLog {
    private const val TAG = "VaultFallback"
    private const val KEY_COUNT = "vault_fallback_count"
    private const val KEY_LAST_SITE = "vault_fallback_last_site"
    private const val KEY_LAST_ERROR = "vault_fallback_last_error"
    private const val KEY_LAST_AT = "vault_fallback_last_at"

    fun record(prefs: SharedPreferences, site: String, error: Throwable, now: Long = System.currentTimeMillis()) {
        try {
            Log.w(TAG, "SecureVault failed at $site — storing plaintext", error)
        } catch (_: RuntimeException) {
            // android.util.Log is not available in JVM unit tests
        }
        try {
            prefs.edit()
                .putInt(KEY_COUNT, prefs.getInt(KEY_COUNT, 0) + 1)
                .putString(KEY_LAST_SITE, site)
                .putString(KEY_LAST_ERROR, "${error.javaClass.simpleName}: ${error.message.orEmpty()}".take(300))
                .putLong(KEY_LAST_AT, now)
                .apply()
        } catch (_: Exception) {
            // Telemetry must never break the caller.
        }
    }

    /** Báo cáo đang chờ (null nếu không có lần fallback nào kể từ lần xoá trước). */
    fun snapshot(prefs: SharedPreferences): Map<String, Any>? {
        val count = prefs.getInt(KEY_COUNT, 0)
        if (count <= 0) return null
        return mapOf(
            "count" to count,
            "site" to (prefs.getString(KEY_LAST_SITE, null) ?: ""),
            "error" to (prefs.getString(KEY_LAST_ERROR, null) ?: ""),
            "at" to prefs.getLong(KEY_LAST_AT, 0L)
        )
    }

    fun clear(prefs: SharedPreferences) {
        prefs.edit().remove(KEY_COUNT).remove(KEY_LAST_SITE).remove(KEY_LAST_ERROR).remove(KEY_LAST_AT).apply()
    }
}
