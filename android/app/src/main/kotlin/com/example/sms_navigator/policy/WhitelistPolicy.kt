package com.example.sms_navigator.policy

import com.example.sms_navigator.util.OtpConfidence

/**
 * Bộ guard trắng danh (deny-by-default) cho SMS relay — pure logic, không phụ thuộc Android.
 */
object WhitelistPolicy {

    const val REASON_WHITELIST_EMPTY = "WHITELIST_BLOCKED_EMPTY"
    const val REASON_NOT_WHITELISTED = "WHITELIST_BLOCKED"
    const val REASON_OTP_NOT_ALLOWED = "OTP_NOT_ALLOWED"
    const val REASON_OTP_SUSPECTED = "OTP_SUSPECTED"

    fun evaluate(
        mode: WhitelistMode,
        entries: List<WhitelistEntry>,
        sender: String,
        otpConfidence: OtpConfidence
    ): RelayDecision {
        val matched = entries.filter { PhoneNormalizer.matches(sender, it.address) }
        val otpAllowed = matched.any { it.allowOtp }

        return when (mode) {
            WhitelistMode.EXPLICIT -> {
                if (matched.isEmpty()) {
                    RelayDecision.Drop(
                        if (entries.isEmpty()) REASON_WHITELIST_EMPTY else REASON_NOT_WHITELISTED
                    )
                } else if (otpConfidence == OtpConfidence.CONFIRMED && !otpAllowed) {
                    RelayDecision.Drop(REASON_OTP_NOT_ALLOWED)
                } else {
                    RelayDecision.Allow
                }
            }

            WhitelistMode.ALL_ADDRESSES -> {
                if (otpConfidence == OtpConfidence.NONE || otpAllowed) {
                    RelayDecision.Allow
                } else {
                    RelayDecision.Drop(
                        if (otpConfidence == OtpConfidence.CONFIRMED) REASON_OTP_NOT_ALLOWED
                        else REASON_OTP_SUSPECTED
                    )
                }
            }
        }
    }
}
