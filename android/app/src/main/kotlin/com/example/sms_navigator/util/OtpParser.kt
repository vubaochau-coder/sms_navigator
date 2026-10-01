package com.example.sms_navigator.util

import com.example.sms_navigator.model.OtpEvent
import java.util.regex.Pattern

enum class OtpConfidence { NONE, SUSPECT, CONFIRMED }

object OtpParser {

    /**
     * Cờ cấu hình: nếu bật, tin nhắn CHỈ chứa chuỗi 4-8 số (không kèm keyword nào)
     * cũng bị đánh giá SUSPECT. Mặc định tắt vì đa số SMS giao dịch đều chứa số.
     */
    @Volatile
    var DIGITS_ONLY_SUSPECT: Boolean = false

    // Từ vựng xác thực — dùng riêng cho bộ phân loại an toàn.
    // Cố ý KHÔNG chứa từ generic ("mã", "ma", "code") để "Mã đơn hàng 452319" không bị coi là OTP.
    private val VERIFICATION_KEYWORDS = listOf(
        "otp",
        "passcode",
        "one time password",
        "one-time password",
        "one time code",
        "one-time code",
        // Vietnamese
        "xác thực",
        "xac thuc",
        "xác minh",
        "xac minh",
        "mã xác thực",
        "ma xac thuc",
        // English
        "verification",
        "verify",
        "security code",
        // Chinese
        "验证码", "驗證碼",
        "校验码", "校驗碼",
        "动态验证码", "動態驗證碼",
        "动态密码", "動態密碼",
        "动态口令", "動態口令",
        "短信验证码", "短信口令",
        "授权码", "授權碼"
    )

    private val KEYWORD_ALTERNATION = VERIFICATION_KEYWORDS.joinToString("|") { Pattern.quote(it) }

    // CONFIRMED: keyword xác thực đứng TRƯỚC chuỗi mã (context sát nhau)
    private val CONFIRMED_FORWARD_REGEX = Pattern.compile(
        """(?:$KEYWORD_ALTERNATION)\D{0,20}?(?<!\d)(\d{4,8})(?!\d)""",
        Pattern.CASE_INSENSITIVE or Pattern.UNICODE_CASE
    )

    // CONFIRMED: chuỗi mã đứng TRƯỚC keyword xác thực (thường gặp trong tiếng Trung)
    private val CONFIRMED_REVERSE_REGEX = Pattern.compile(
        """(?<!\d)(\d{4,8})(?!\d)\D{0,15}?(?:$KEYWORD_ALTERNATION)""",
        Pattern.CASE_INSENSITIVE or Pattern.UNICODE_CASE
    )

    // Keywords that indicate an OTP / verification message (Vietnamese, English, Chinese)
    private val OTP_KEYWORDS = listOf(
        // Vietnamese
        "otp",
        "mã",
        "ma",
        "xác thực",
        "xac thuc",
        "xác nhận",
        "xac nhan",
        // English
        "code",
        "verification",
        "verify",
        "passcode",
        "security code",
        "one time password",
        // Chinese (Simplified & Traditional)
        "验证码", // Yan zheng ma (Verification code)
        "驗證碼",
        "校验码", // Jiao yan ma (Check code)
        "校驗碼",
        "动态码", // Dong tai ma (Dynamic code)
        "動態碼",
        "动态密码", // Dong tai mi ma (Dynamic password)
        "動態密碼",
        "动态口令", // Dong tai kou ling (Dynamic token)
        "動態口令",
        "短信口令", // Duan xin kou ling (SMS token)
        "短信验证码", // Duan xin yan zheng ma (SMS verification code)
        "授权码", // Shou quan ma (Authorization code)
        "授權碼",
        "确认码", // Que ren ma (Confirmation code)
        "確認碼",
        "安全码", // An quan ma (Security code)
        "安全碼",
        "认证码", // Ren zheng ma (Authentication code)
        "認證碼",
        "验证代码", // Yan zheng dai ma
        "随机码", // Sui ji ma (Random code)
        "口令"    // Kou ling (Passphrase/code)
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
        "quảng cáo",
        "退订回", // Chinese unsubscribe promo text
        "回T退订"
    )

    // Contextual forward regex: Keyword precedes code
    // Uses lookaround (?<!\d)(\d{4,8})(?!\d) instead of \b\d{4,8}\b for unicode/CJK safety
    private val FORWARD_OTP_REGEX = Pattern.compile(
        """(?:otp|mã|ma|code|passcode|xác thực|xac thuc|verification|verify|验证码|驗證碼|校验码|校驗碼|动态码|動態碼|动态密码|動態密碼|动态口令|動態口令|短信口令|短信验证码|授权码|授權碼|确认码|確認碼|安全码|安全碼|认证码|認證碼|验证代码|随机码|口令)\D{0,20}?(?<!\d)(\d{4,8})(?!\d)""",
        Pattern.CASE_INSENSITIVE or Pattern.UNICODE_CASE
    )

    // Contextual reverse regex: Code precedes keyword (common in Chinese: "849201（动态验证码）" or "849201 为您的验证码")
    private val REVERSE_OTP_REGEX = Pattern.compile(
        """(?<!\d)(\d{4,8})(?!\d)\D{0,15}?(?:为您的|是您的|（动态验证码）|作為您的|作为您的|即为|为)?(?:验证码|驗證碼|校验码|校驗碼|动态码|動態碼|动态密码|動態密碼|动态口令|動態口令|短信口令|短信验证码|授权码|授權碼|确认码|確認碼|安全码|安全碼|认证码|認證碼|验证代码|随机码|口令|otp|code)""",
        Pattern.CASE_INSENSITIVE or Pattern.UNICODE_CASE
    )

    // Fallback general 4-8 digits regex (unicode/CJK safe)
    private val GENERAL_DIGITS_REGEX = Pattern.compile(
        """(?<!\d)(\d{4,8})(?!\d)"""
    )

    /**
     * Extracts an OtpEvent if the message is deemed an authentic OTP SMS.
     * Returns null if the SMS does not qualify as an OTP.
     */
    fun extractOtp(sender: String, body: String): OtpEvent? {
        if (body.isBlank()) return null

        val lowerBody = body.lowercase()

        // 1. Check for OTP keywords
        val hasOtpKeyword = OTP_KEYWORDS.any { lowerBody.contains(it.lowercase()) }
        if (!hasOtpKeyword) {
            return null
        }

        // 2. Check if contains negative keywords without strong OTP context
        val hasNegative = NEGATIVE_KEYWORDS.any { lowerBody.contains(it.lowercase()) }
        if (hasNegative &&
            !lowerBody.contains("otp") &&
            !lowerBody.contains("mã xác thực") &&
            !lowerBody.contains("verification code") &&
            !lowerBody.contains("验证码") &&
            !lowerBody.contains("动态密码")
        ) {
            return null
        }

        // 3. Try forward contextual regex first: "验证码是 849201", "Ma OTP: 123456"
        val forwardMatcher = FORWARD_OTP_REGEX.matcher(body)
        if (forwardMatcher.find()) {
            val code = forwardMatcher.group(1)
            if (code != null && code.length in 4..8) {
                return OtpEvent(
                    sender = sender,
                    otp = code,
                    fullMessage = body
                )
            }
        }

        // 4. Try reverse contextual regex: "849201 为您的验证码", "849201 (dynamic code)"
        val reverseMatcher = REVERSE_OTP_REGEX.matcher(body)
        if (reverseMatcher.find()) {
            val code = reverseMatcher.group(1)
            if (code != null && code.length in 4..8) {
                return OtpEvent(
                    sender = sender,
                    otp = code,
                    fullMessage = body
                )
            }
        }

        // 5. Try fallback digits regex if strong keyword matched
        val fallbackMatcher = GENERAL_DIGITS_REGEX.matcher(body)
        while (fallbackMatcher.find()) {
            val candidate = fallbackMatcher.group(1)
            if (candidate != null && candidate.length in 4..8) {
                return OtpEvent(
                    sender = sender,
                    otp = candidate,
                    fullMessage = body
                )
            }
        }

        return null
    }

    /**
     * Finds any 4-8 digit number in the text as a representative identifier for full-SMS relay.
     * Returns null if no suitable digits are found.
     */
    fun findAnyDigits(body: String): String? {
        val matcher = GENERAL_DIGITS_REGEX.matcher(body)
        if (matcher.find()) {
            return matcher.group(1)
        }
        return null
    }

    /**
     * Phân loại độ tin cậy "tin này là OTP" cho guard white-list:
     * - CONFIRMED: keyword xác thực kèm mã theo ngữ cảnh chặt (forward/reverse).
     * - SUSPECT: chỉ có keyword xác thực + chuỗi 4-8 số (không theo ngữ cảnh chặt).
     * - NONE: không có tín hiệu OTP (tin SMS thường).
     */
    fun classifyConfidence(body: String): OtpConfidence {
        if (body.isBlank()) return OtpConfidence.NONE

        if (CONFIRMED_FORWARD_REGEX.matcher(body).find() ||
            CONFIRMED_REVERSE_REGEX.matcher(body).find()
        ) {
            return OtpConfidence.CONFIRMED
        }

        val hasDigitRun = GENERAL_DIGITS_REGEX.matcher(body).find()
        if (!hasDigitRun) return OtpConfidence.NONE

        val lowerBody = body.lowercase()
        val hasVerificationKeyword = VERIFICATION_KEYWORDS.any { lowerBody.contains(it) }
        return if (DIGITS_ONLY_SUSPECT || hasVerificationKeyword) {
            OtpConfidence.SUSPECT
        } else {
            OtpConfidence.NONE
        }
    }
}
