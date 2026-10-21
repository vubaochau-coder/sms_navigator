package com.example.sms_navigator.channel

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Lưu / mở file sao lưu `.smsnav` qua Storage Access Framework (BACKLOG 1.1).
 *
 * Không cần quyền bộ nhớ: người dùng tự chọn nơi lưu (Downloads, Drive…) qua
 * `ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT`. Nội dung đã được Dart mã
 * hoá bằng passphrase trước khi xuống đây — native chỉ ghi/đọc byte.
 *
 * - `saveFile({fileName, bytes})` → `true` đã lưu, `false` người dùng huỷ.
 * - `openFile()` → `ByteArray` hoặc `null` nếu huỷ.
 */
class BackupFileChannel(
    messenger: BinaryMessenger,
    private val activity: Activity
) {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    fun register() {
        channel.setMethodCallHandler { call, result ->
            if (pendingResult != null) {
                result.error("BUSY", "Another file request is in progress", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "saveFile" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "backup.smsnav"
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_ARGS", "bytes is required", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = MIME_TYPE
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    start(intent, REQUEST_SAVE, result, bytes)
                }

                "openFile" -> {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        // Nhiều trình quản lý file không biết đuôi .smsnav → cho chọn mọi file.
                        type = "*/*"
                    }
                    start(intent, REQUEST_OPEN, result, null)
                }

                else -> result.notImplemented()
            }
        }
    }

    fun unregister() {
        channel.setMethodCallHandler(null)
        pendingResult?.error("DETACHED", "Activity destroyed", null)
        clearPending()
    }

    /** Gọi từ `MainActivity.onActivityResult`. Trả `true` nếu request thuộc channel này. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) return false
        val result = pendingResult ?: return true
        val bytes = pendingBytes
        clearPending()

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (requestCode == REQUEST_SAVE) false else null)
            return true
        }

        // I/O ngoài main thread; trả kết quả về main thread (yêu cầu của MethodChannel).
        Thread {
            try {
                if (requestCode == REQUEST_SAVE) {
                    write(uri, bytes ?: ByteArray(0))
                    mainHandler.post { result.success(true) }
                } else {
                    val content = read(uri)
                    mainHandler.post { result.success(content) }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Backup file I/O failed: ${e.message}", e)
                mainHandler.post { result.error("IO_ERROR", e.message, null) }
            }
        }.start()
        return true
    }

    private fun start(intent: Intent, requestCode: Int, result: MethodChannel.Result, bytes: ByteArray?) {
        pendingResult = result
        pendingBytes = bytes
        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            clearPending()
            result.error("NO_PICKER", e.message, null)
        }
    }

    private fun write(uri: Uri, bytes: ByteArray) {
        // "wt" = truncate nếu người dùng chọn ghi đè file cũ.
        activity.contentResolver.openOutputStream(uri, "wt")?.use { it.write(bytes) }
            ?: throw IllegalStateException("Cannot open output stream")
    }

    private fun read(uri: Uri): ByteArray {
        val input = activity.contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Cannot open input stream")
        input.use { stream ->
            val bytes = stream.readBytes()
            require(bytes.size <= MAX_FILE_BYTES) { "Backup file too large" }
            return bytes
        }
    }

    private fun clearPending() {
        pendingResult = null
        pendingBytes = null
    }

    companion object {
        private const val TAG = "BackupFileChannel"
        const val CHANNEL = "com.example.sms_navigator/backup_file"
        private const val MIME_TYPE = "application/octet-stream"
        private const val REQUEST_SAVE = 0x5A01
        private const val REQUEST_OPEN = 0x5A02
        /** Bản sao lưu thực tế vài KB; chặn chọn nhầm file lớn. */
        private const val MAX_FILE_BYTES = 2 * 1024 * 1024
    }
}
