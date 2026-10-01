package com.example.sms_navigator.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Base64
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
import com.example.sms_navigator.util.OtpCrypto
import com.example.sms_navigator.util.OtpParser
import com.example.sms_navigator.worker.OtpRelayWorker
import java.util.concurrent.TimeUnit

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        val pendingResult = goAsync()

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) {
                pendingResult.finish()
                return
            }

            // Group parts by originating address (sender)
            val sender = messages[0].displayOriginatingAddress ?: "Unknown"
            val fullBody = StringBuilder()
            for (sms in messages) {
                fullBody.append(sms.displayMessageBody)
            }
            val messageText = fullBody.toString()

            Log.d(TAG, "Received SMS from: $sender")

            // 1. Check Relay Configuration first
            val prefs = OtpPreferences(context)
            if (!prefs.isRelayEnabled) {
                Log.d(TAG, "Relay is disabled in settings, skipping.")
                pendingResult.finish()
                return
            }

            val pairId = prefs.pairId
            val sharedSecretBase64 = prefs.sharedSecretBase64
            if (pairId.isNullOrBlank() || sharedSecretBase64.isNullOrBlank()) {
                Log.w(TAG, "Device is not paired yet. Cannot relay.")
                pendingResult.finish()
                return
            }

            // 2. Whitelist guard (deny-by-default)
            val (whitelistMode, whitelistEntries) = prefs.getWhitelistConfig()
            val otpConfidence = OtpParser.classifyConfidence(messageText)
            when (val decision = WhitelistPolicy.evaluate(whitelistMode, whitelistEntries, sender, otpConfidence)) {
                is RelayDecision.Drop -> {
                    Log.i(TAG, "Dropping SMS from $sender: ${decision.reason}")
                    prefs.addRelayLog(sender, "", "BLOCKED", decision.reason)
                    pendingResult.finish()
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
                Log.i(TAG, "Detected OTP: ${otpEvent.otp} from $sender")
            }

            // 4. Deduplication Check (FR-013)
            val deduplicationKey = if (otpEvent.otp == "SMS") {
                "SMS_${messageText.hashCode()}"
            } else {
                otpEvent.otp
            }

            if (prefs.isDuplicateAndRecord(sender, deduplicationKey)) {
                Log.w(TAG, "Duplicate message/OTP received within TTL window. Dropping.")
                pendingResult.finish()
                return
            }

            // 4. End-to-End Encryption (FR-014, NFR-004)
            val secretKeyBytes = Base64.decode(sharedSecretBase64, Base64.NO_WRAP)
            val encrypted = OtpCrypto.encrypt(otpEvent.toJson(), secretKeyBytes)

            // 5. Enqueue reliable delivery via WorkManager (FR-015, NFR-003)
            val messageId = java.util.UUID.randomUUID().toString()
            val inputData = Data.Builder()
                .putString(OtpRelayWorker.KEY_MESSAGE_ID, messageId)
                .putString(OtpRelayWorker.KEY_PAIR_ID, pairId)
                .putString(OtpRelayWorker.KEY_ENCRYPTED_PAYLOAD, encrypted.ciphertextBase64)
                .putString(OtpRelayWorker.KEY_IV, encrypted.ivBase64)
                .putString(OtpRelayWorker.KEY_SENDER, sender)
                .putString(OtpRelayWorker.KEY_OTP, otpEvent.otp)
                .putString(OtpRelayWorker.KEY_RELAY_URL, prefs.relayUrl)
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
            Log.i(TAG, "Enqueued OtpRelayWorker with WorkManager (messageId: $messageId)")

            // Notify UI if app is currently in foreground
            onOtpProcessedListener?.invoke(otpEvent.sender, otpEvent.otp)

        } catch (e: Exception) {
            Log.e(TAG, "Error in SmsReceiver: ${e.message}", e)
        } finally {
            pendingResult.finish()
        }
    }

    companion object {
        private const val TAG = "SmsReceiver"

        // Optional callback to notify running Flutter activity in real-time
        var onOtpProcessedListener: ((sender: String, otp: String) -> Unit)? = null
    }
}
