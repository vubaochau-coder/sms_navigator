package com.example.sms_navigator.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.data.RelayChannelStore
import com.example.sms_navigator.policy.RelayDecision
import com.example.sms_navigator.policy.WhitelistPolicy
import com.example.sms_navigator.util.OtpConfidence
import com.example.sms_navigator.util.OtpParser
import com.example.sms_navigator.worker.RelayWorkScheduler

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
            // Một id cho cả SMS: mọi dòng nhật ký (từng kênh, từng lần thử) gom về một mục.
            val smsId = java.util.UUID.randomUUID().toString()

            Log.i(TAG, "Received SMS from: $sender")

            // 1. Relay configuration: every Owner channel with a usable key
            val prefs = OtpPreferences(context)
            val store = RelayChannelStore(prefs)
            val channels = store.all().filter { it.activeKey != null }
            val token = prefs.deviceToken
            if (channels.isEmpty() || token.isNullOrBlank()) {
                Log.w(TAG, "No relay channel or device token configured. Cannot relay.")
                prefs.addRelayLog(sender, "", "SKIPPED", "No active channel configured", smsId = smsId)
                finishOnce(pendingResult)
                return
            }

            // 2. Classify once — the result is the same for every channel
            val otpConfidence = OtpParser.classifyConfidence(messageText)
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
            val deduplicationKey = if (otpEvent.otp == "SMS") {
                "SMS_${messageText.hashCode()}"
            } else {
                otpEvent.otp
            }

            // 3. Fan out: each channel applies its own whitelist and gets its
            //    own worker, so one channel failing/retrying never blocks another.
            for (channel in channels) {
                val label = channel.name.ifBlank { channel.channelId }

                val (whitelistMode, whitelistEntries) = prefs.getWhitelistConfig(channel.channelId)
                when (val decision = WhitelistPolicy.evaluate(whitelistMode, whitelistEntries, sender, otpConfidence)) {
                    is RelayDecision.Drop -> {
                        Log.i(TAG, "Dropping SMS from $sender for channel $label: ${decision.reason}")
                        prefs.addRelayLog(
                            sender, "", "BLOCKED", "[$label] ${decision.reason}",
                            smsId = smsId, channelId = channel.channelId, channelName = label
                        )
                        continue
                    }
                    RelayDecision.Allow -> Unit
                }

                // Deduplication per channel (FR-013)
                if (prefs.isDuplicateAndRecord("${channel.channelId}|$sender", deduplicationKey)) {
                    Log.w(TAG, "Duplicate within TTL window for channel $label. Dropping.")
                    prefs.addRelayLog(
                        sender, otpEvent.otp, "SKIPPED", "[$label] Duplicate within TTL window",
                        smsId = smsId, channelId = channel.channelId, channelName = label
                    )
                    continue
                }

                // Reliable delivery via WorkManager (FR-015, NFR-003)
                val messageId = java.util.UUID.randomUUID().toString()
                RelayWorkScheduler.enqueue(context, messageId, channel.channelId, sender, messageText, smsId)
                Log.i(TAG, "Enqueued OtpRelayWorker (messageId: $messageId, channel: $label)")
                prefs.addRelayLog(
                    sender, otpEvent.otp, "ENQUEUED", "Worker → V2 Kênh $label",
                    smsId = smsId, channelId = channel.channelId, channelName = label
                )
            }
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
