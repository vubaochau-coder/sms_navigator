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
 * Worker chỉ nhận channelId: key và epoch được đọc từ RelayChannelStore lúc
 * worker chạy, nên một rotation xảy ra sau khi enqueue vẫn dùng đúng key mới.
 *
 * Nội dung SMS + sender KHÔNG đi qua inputData (lưu thô trong SQLite của
 * WorkManager): được ghi mã hóa vào outbox của RelayChannelStore, worker đọc
 * theo messageId rồi xóa khi xong.
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
        RelayChannelStore(OtpPreferences(context)).putOutgoing(
            ParkedMessage(messageId, channelId, sender, messageText, System.currentTimeMillis())
        )

        val inputData = Data.Builder()
            .putString(OtpRelayWorker.KEY_MESSAGE_ID, messageId)
            .putString(OtpRelayWorker.KEY_CHANNEL_ID, channelId)
            .build()

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
}
