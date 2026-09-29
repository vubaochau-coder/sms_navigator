package com.example.sms_navigator.util

import com.example.sms_navigator.model.OtpEvent
import java.util.regex.Pattern

object OtpParser {

    // Keywords that indicate an OTP / verification message
    private val OTP_KEYWORDS = listOf(
        "otp",
        "mã",
        "ma",
        "code",
        "xác thực",
        "xac thuc",
        "xác nhận",
        "xac nhan",
        "verification",
        "verify",
        "passcode",
        "security code",
        "one time password"
    )

    // Negative keywords to filter out non-OTP messages (e.g. promotional or balance notifications)
    private val NEGATIVE_KEYWORDS = listOf(
        "khuyen mai",
        "khuyến mại",
        "khuyenmai",
        "goi cuoc",
        "gói cước",
        "nap the",
        "nạp thẻ",
        "so du",
        "số dư",
        "bien dong so du",
        "quang cao",
        "quảng cáo"
    )

    // Regex to match OTP near keywords first: e.g. "ma otp cua ban la 583921", "code: 123456"
    private val CONTEXTUAL_OTP_REGEX = Pattern.compile(
        """(?:otp|mã|ma|code|passcode|xác thực|xac thuc|verification)\D{0,20}(\b\d{4,8}\b)""",
        Pattern.CASE_INSENSITIVE or Pattern.UNICODE_CASE
    )

    // Fallback general 4-8 digits regex when strong OTP keyword is present
    private val GENERAL_OTP_REGEX = Pattern.compile(
        """\b\d{4,8}\b"""
    )

    /**
     * Extracts an OtpEvent if the message is deemed an authentic OTP SMS.
     * Returns null if the SMS does not qualify as an OTP.
     */
    fun extractOtp(sender: String, body: String): OtpEvent? {
        if (body.isBlank()) return null

        val lowerBody = body.lowercase()

        // 1. Check if contains negative keywords without strong OTP context
        val hasNegative = NEGATIVE_KEYWORDS.any { lowerBody.contains(it) }

        // 2. Check for OTP keywords
        val hasOtpKeyword = OTP_KEYWORDS.any { lowerBody.contains(it) }
        if (!hasOtpKeyword) {
            return null
        }

        // If it has negative keywords (e.g., "khuyen mai"), ensure it really is an OTP request before processing
        if (hasNegative && !lowerBody.contains("otp") && !lowerBody.contains("mã xác thực") && !lowerBody.contains("verification code")) {
            return null
        }

        // 3. Try contextual regex first
        val contextualMatcher = CONTEXTUAL_OTP_REGEX.matcher(body)
        if (contextualMatcher.find()) {
            val code = contextualMatcher.group(1)
            if (code != null && code.length in 4..8) {
                return OtpEvent(
                    sender = sender,
                    otp = code,
                    fullMessage = body
                )
            }
        }

        // 4. Try fallback digits regex if strong keyword matched
        val fallbackMatcher = GENERAL_OTP_REGEX.matcher(body)
        while (fallbackMatcher.find()) {
            val candidate = fallbackMatcher.group()
            // Ignore obvious years (e.g. 2024, 2025, 2026) or phone numbers if not OTP
            if (candidate.length in 4..8) {
                return OtpEvent(
                    sender = sender,
                    otp = candidate,
                    fullMessage = body
                )
            }
        }

        return null
    }
}
