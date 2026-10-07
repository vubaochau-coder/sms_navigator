package com.example.sms_navigator.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.policy.RelayDecision
import com.example.sms_navigator.policy.WhitelistPolicy
import com.example.sms_navigator.util.OtpConfidence
import com.example.sms_navigator.util.OtpParser
import com.example.sms_navigator.worker.OtpRelayWorker
import java.util.concurrent.TimeUnit

class SmsReceiver : BroadcastReceiver() {

    private var finished = false

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        val pendingResult = goAsync()

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) {
                OtpPreferences(context).addRelayLog("Unknown", "", "SKIPPED", "No SMS parts in intent")
                finishOnce(pendingResult)
                return
            }

            // Group parts by originating address (sender)
            val sender = messages[0].displayOriginatingAddress ?: "Unknown"
            val fullBody = StringBuilder()
            for (sms in messages) {
                fullBody.append(sms.displayMessageBody)
            }
            val messageText = fullBody.toString()

            Log.i(TAG, "Received SMS from: $sender")

            // 1. Check Relay Configuration first
            val prefs = OtpPreferences(context)
            val channelId = prefs.activeChannelId
            val channelKeyBase64 = prefs.activeChannelKeyBase64
            val token = prefs.deviceToken
            if (channelId.isNullOrBlank() || channelKeyBase64.isNullOrBlank() || token.isNullOrBlank()) {
                Log.w(TAG, "No active channel or device token configured. Cannot relay.")
                prefs.addRelayLog(sender, "", "SKIPPED", "No active channel configured")
                finishOnce(pendingResult)
                return
            }

            // 2. Whitelist guard (deny-by-default)
            val (whitelistMode, whitelistEntries) = prefs.getWhitelistConfig()
            val otpConfidence = OtpParser.classifyConfidence(messageText)
            when (val decision = WhitelistPolicy.evaluate(whitelistMode, whitelistEntries, sender, otpConfidence)) {
                is RelayDecision.Drop -> {
                    Log.i(TAG, "Dropping SMS from $sender: ${decision.reason}")
                    prefs.addRelayLog(sender, "", "BLOCKED", decision.reason)
                    finishOnce(pendingResult)
                    return
                }
                RelayDecision.Allow -> Unit
            }

            // 3. Detect OTP or relay the full SMS (whitelist already granted)
            val otpEvent = OtpParser.extractOtp(sender, messageText)
                ?: com.example.sms_navigator.model.OtpEvent(
                    sender = sender,
                    otp = OtpParser.findAnyDigits(messageText) ?: "SMS",
                    fullMessage = messageText
                )

            if (otpEvent.otp == "SMS") {
                Log.i(TAG, "Relaying full SMS from $sender (no digits found)")
            } else if (otpConfidence == OtpConfidence.CONFIRMED) {
                Log.i(TAG, "Detected OTP (length: ${otpEvent.otp.length}) from $sender")
            }

            // 4. Deduplication Check (FR-013)
            val deduplicationKey = if (otpEvent.otp == "SMS") {
                "SMS_${messageText.hashCode()}"
            } else {
                otpEvent.otp
            }

            if (prefs.isDuplicateAndRecord(sender, deduplicationKey)) {
                Log.w(TAG, "Duplicate message/OTP received within TTL window. Dropping.")
                prefs.addRelayLog(sender, otpEvent.otp, "SKIPPED", "Duplicate within TTL window")
                finishOnce(pendingResult)
                return
            }

            // 5. Enqueue reliable delivery via WorkManager (FR-015, NFR-003)
            val messageId = java.util.UUID.randomUUID().toString()
            val inputData = Data.Builder()
                .putString(OtpRelayWorker.KEY_MESSAGE_ID, messageId)
                .putString(OtpRelayWorker.KEY_CHANNEL_ID, channelId)
                .putLong(OtpRelayWorker.KEY_CHANNEL_EPOCH, prefs.activeChannelEpoch)
                .putString(OtpRelayWorker.KEY_MESSAGE_TEXT, messageText)
                .putString(OtpRelayWorker.KEY_SENDER, sender)
                .putString(OtpRelayWorker.KEY_API_BASE_URL, prefs.apiBaseUrl)
                .build()

            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val workRequest = OneTimeWorkRequestBuilder<OtpRelayWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .setInputData(inputData)
                .build()

            WorkManager.getInstance(context).enqueue(workRequest)
            val channelDisplayName = prefs.activeChannelName ?: channelId
            Log.i(TAG, "Enqueued OtpRelayWorker with WorkManager (messageId: $messageId, channel: $channelDisplayName)")
            prefs.addRelayLog(sender, otpEvent.otp, "ENQUEUED", "Worker → V2 Kênh $channelDisplayName")

        } catch (t: Throwable) {
            Log.e(TAG, "Error in SmsReceiver: ${t.message}", t)
        } finally {
            finishOnce(pendingResult)
        }
    }

    /** FR: goAsync() requires exactly one finish() — guard against double-finish
     * (IllegalStateException "Broadcast already finished" killed the process). */
    private fun finishOnce(pendingResult: PendingResult) {
        if (finished) return
        finished = true
        pendingResult.finish()
    }

    companion object {
        private const val TAG = "SmsReceiver"
    }
}
