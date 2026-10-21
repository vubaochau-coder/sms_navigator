package com.example.sms_navigator.worker

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Điểm duy nhất enqueue [OtpRelayWorker] — dùng chung cho SmsReceiver (SMS mới)
 * và RelayMethodChannel (gửi lại tin "parked" sau khi app đồng bộ key).
 *
 * Worker chỉ nhận channelId: key và epoch được đọc từ RelayChannelStore lúc
 * worker chạy, nên một rotation xảy ra sau khi enqueue vẫn dùng đúng key mới.
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
        val inputData = Data.Builder()
            .putString(OtpRelayWorker.KEY_MESSAGE_ID, messageId)
            .putString(OtpRelayWorker.KEY_CHANNEL_ID, channelId)
            .putString(OtpRelayWorker.KEY_MESSAGE_TEXT, messageText)
            .putString(OtpRelayWorker.KEY_SENDER, sender)
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
