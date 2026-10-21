package com.example.sms_navigator.worker

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.data.ParkedMessage
import com.example.sms_navigator.data.RelayChannelStore
import java.util.concurrent.TimeUnit

/**
 * Điểm duy nhất enqueue [OtpRelayWorker] — dùng chung cho SmsReceiver (SMS mới)
 * và RelayMethodChannel (gửi lại tin "parked" sau khi app đồng bộ key).
 *
 * Worker chỉ nhận channelId + outboxId: key và epoch được đọc từ
 * RelayChannelStore lúc worker chạy, nên một rotation xảy ra sau khi enqueue
 * vẫn dùng đúng key mới.
 *
 * Nội dung SMS **không** đi vào `inputData` (WorkManager lưu nó trong SQLite
 * không mã hoá). Text + sender nằm trong outbox mã hoá của
 * [RelayChannelStore] (BACKLOG 2.1).
 */
object RelayWorkScheduler {
    const val TAG_RELAY = "otp_relay"

    fun enqueue(
        context: Context,
        messageId: String,
        channelId: String,
        sender: String,
        messageText: String
    ) {
        val store = RelayChannelStore(OtpPreferences(context))
        val outboxId = store.putOutbox(
            ParkedMessage(messageId, channelId, sender, messageText, System.currentTimeMillis())
        )
        val inputData = buildInputData(messageId, channelId, outboxId)

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val request = OneTimeWorkRequestBuilder<OtpRelayWorker>()
            .setConstraints(constraints)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .setInputData(inputData)
            .addTag(TAG_RELAY)
            .build()

        WorkManager.getInstance(context).enqueue(request)
    }

    /** Chỉ id — không bao giờ có nội dung SMS hay sender. */
    internal fun buildInputData(messageId: String, channelId: String, outboxId: String): Data =
        Data.Builder()
            .putString(OtpRelayWorker.KEY_MESSAGE_ID, messageId)
            .putString(OtpRelayWorker.KEY_CHANNEL_ID, channelId)
            .putString(OtpRelayWorker.KEY_OUTBOX_ID, outboxId)
            .build()
}
