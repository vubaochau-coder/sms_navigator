package com.example.sms_navigator

import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.model.OtpEvent
import com.example.sms_navigator.util.OtpParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.MessageDigest

/**
 * Kiểm thử tầng Java/Kotlin native cho nghiệp vụ Nhận Diện Tin Nhắn:
 * - Nhận diện người gửi theo Whitelist (đầu số quốc tế, brandname, số điện thoại, định dạng linh hoạt).
 * - Nhận diện và phân loại tin nhắn theo Chế độ chuyển tiếp (MODE_OTP_ONLY, MODE_ALL_SMS, MODE_WHITELIST_ALL).
 * - Nhận diện và lọc trùng lặp tin nhắn (Deduplication & Replay attack prevention).
 */
class MessageRecognitionTest {

    // ==========================================
    // 1. NHẬN DIỆN NGƯỜI GỬI THEO WHITELIST (SENDER WHITELIST RECOGNITION)
    // ==========================================

    /**
     * Thuật toán kiểm tra whitelist tương tự OtpPreferences.isSenderWhitelisted
     * để kiểm thử độc lập mà không cần Android Context mock phức tạp.
     */
    private fun checkSenderWhitelisted(sender: String, whitelist: List<String>): Boolean {
        if (sender.isBlank()) return false
        val cleanSender = sender.replace(Regex("""[\s\-\(\)]"""), "").lowercase()
        if (whitelist.isEmpty()) return false

        return whitelist.any { rawItem ->
            val cleanItem = rawItem.replace(Regex("""[\s\-\(\)]"""), "").lowercase()
            if (cleanItem.isBlank()) false
            else {
                cleanSender.startsWith(cleanItem) ||
                cleanSender == cleanItem ||
                cleanSender.contains(cleanItem)
            }
        }
    }

    @Test
    fun testRecognizeSenderByInternationalPrefix() {
        // Whitelist cấu hình đầu số Trung Quốc (+86, 1069) và đầu số Việt Nam (+84, 090)
        val whitelist = listOf("+86", "1069", "+84", "090")

        // Đầu số Trung Quốc
        assertTrue("Should recognize China international prefix +86",
            checkSenderWhitelisted("+8613800138000", whitelist))
        assertTrue("Should recognize China enterprise SMS gateway 1069",
            checkSenderWhitelisted("10690001888", whitelist))

        // Đầu số Việt Nam
        assertTrue("Should recognize Vietnam international prefix +84",
            checkSenderWhitelisted("+84987654321", whitelist))
        assertTrue("Should recognize domestic prefix 090",
            checkSenderWhitelisted("0909123456", whitelist))

        // Đầu số không thuộc whitelist
        assertFalse("Should reject non-whitelisted USA prefix +1",
            checkSenderWhitelisted("+12025550199", whitelist))
        assertFalse("Should reject non-whitelisted prefix 091",
            checkSenderWhitelisted("0912345678", whitelist))
    }

    @Test
    fun testRecognizeSenderByBrandname() {
        val whitelist = listOf("Viettel", "TPBank", "Techcombank", "Alipay", "WeChat", "招商银行")

        assertTrue("Should recognize brandname Viettel", checkSenderWhitelisted("Viettel", whitelist))
        assertTrue("Should recognize brandname TPBank case-insensitively", checkSenderWhitelisted("tpbank", whitelist))
        assertTrue("Should recognize brandname Alipay", checkSenderWhitelisted("Alipay", whitelist))
        assertTrue("Should recognize brandname WeChat", checkSenderWhitelisted("WeChat", whitelist))
        assertTrue("Should recognize Chinese brandname 招商银行", checkSenderWhitelisted("招商银行", whitelist))

        assertFalse("Should reject unknown brandname Vietcombank", checkSenderWhitelisted("Vietcombank", whitelist))
        assertFalse("Should reject spam brandname LoanNow", checkSenderWhitelisted("LoanNow", whitelist))
    }

    @Test
    fun testRecognizeSenderWithPunctuationAndSpacing() {
        val whitelist = listOf("+8490", "0901234567")

        // Số điện thoại chứa dấu ngoặc đơn, gạch ngang, dấu cách
        assertTrue("Should recognize normalized phone number with spaces",
            checkSenderWhitelisted("+84 90 123 4567", whitelist))
        assertTrue("Should recognize normalized phone number with dashes",
            checkSenderWhitelisted("090-123-4567", whitelist))
        assertTrue("Should recognize normalized phone number with parentheses",
            checkSenderWhitelisted("+84 (90) 1234567", whitelist))
    }

    // ==========================================
    // 2. PHÂN LOẠI TIN NHẮN THEO CHẾ ĐỘ (RELAY MODE DECISION)
    // ==========================================

    data class RecognitionResult(
        val shouldRelay: Boolean,
        val otpEvent: OtpEvent?,
        val reason: String
    )

    /**
     * Mô phỏng logic ra quyết định nhận diện tin nhắn trong SmsReceiver
     */
    private fun processIncomingSms(
        sender: String,
        messageText: String,
        relayMode: String,
        whitelist: List<String>
    ): RecognitionResult {
        val isWhitelisted = checkSenderWhitelisted(sender, whitelist)
        val isForwardAllMode = (relayMode == OtpPreferences.MODE_ALL_SMS) ||
                              (relayMode == OtpPreferences.MODE_WHITELIST_ALL && isWhitelisted)

        val detectedOtp = OtpParser.extractOtp(sender, messageText)

        return if (detectedOtp != null) {
            RecognitionResult(
                shouldRelay = true,
                otpEvent = detectedOtp,
                reason = "Detected OTP: ${detectedOtp.otp}"
            )
        } else if (isForwardAllMode) {
            val digits = OtpParser.findAnyDigits(messageText) ?: "SMS"
            RecognitionResult(
                shouldRelay = true,
                otpEvent = OtpEvent(sender = sender, otp = digits, fullMessage = messageText),
                reason = "Forwarding full SMS in mode $relayMode"
            )
        } else {
            RecognitionResult(
                shouldRelay = false,
                otpEvent = null,
                reason = "Not an OTP and sender is not in forward-all mode"
            )
        }
    }

    @Test
    fun testModeOtpOnlyRecognizesOnlyOtpMessages() {
        val whitelist = emptyList<String>()
        val mode = OtpPreferences.MODE_OTP_ONLY

        // 1. Tin nhắn có mã OTP -> Được nhận diện và chấp nhận chuyển tiếp
        val otpSms = "Mã xác thực của bạn là 123456."
        val res1 = processIncomingSms("TPBank", otpSms, mode, whitelist)
        assertTrue("OTP message should be accepted in MODE_OTP_ONLY", res1.shouldRelay)
        assertEquals("123456", res1.otpEvent?.otp)

        // 2. Tin nhắn thông thường không có OTP -> Bị từ chối
        val normalSms = "Cảm ơn quý khách đã mua sắm tại cửa hàng. Hẹn gặp lại quý khách!"
        val res2 = processIncomingSms("ShopA", normalSms, mode, whitelist)
        assertFalse("Non-OTP message should be rejected in MODE_OTP_ONLY", res2.shouldRelay)
        assertNull(res2.otpEvent)
    }

    @Test
    fun testModeAllSmsRecognizesAnyMessage() {
        val whitelist = emptyList<String>()
        val mode = OtpPreferences.MODE_ALL_SMS

        // 1. Tin nhắn có OTP
        val otpSms = "Mã OTP là 998877."
        val res1 = processIncomingSms("Viettel", otpSms, mode, whitelist)
        assertTrue(res1.shouldRelay)
        assertEquals("998877", res1.otpEvent?.otp)

        // 2. Tin nhắn ngân hàng biến động số dư (có 4 số đuôi thẻ)
        val bankSms = "Tài khoản 9876 biến động -500,000 VND."
        val res2 = processIncomingSms("VCB", bankSms, mode, whitelist)
        assertTrue("In MODE_ALL_SMS, bank notification should be forwarded", res2.shouldRelay)
        assertEquals("9876", res2.otpEvent?.otp)

        // 3. Tin nhắn thuần chữ (không có bất kỳ con số nào)
        val textOnlySms = "Chúc bạn một ngày tốt lành và nhiều may mắn!"
        val res3 = processIncomingSms("Friend", textOnlySms, mode, whitelist)
        assertTrue("In MODE_ALL_SMS, text-only SMS should also be forwarded with 'SMS' tag", res3.shouldRelay)
        assertEquals("SMS", res3.otpEvent?.otp)
    }

    @Test
    fun testModeWhitelistAllRecognizesFullSmsOnlyForWhitelistedSenders() {
        val whitelist = listOf("Techcombank", "+8613800000000")
        val mode = OtpPreferences.MODE_WHITELIST_ALL

        // 1. Sender trong whitelist gửi SMS thường (không có OTP) -> ĐƯỢC CHẤP NHẬN
        val whitelistedNormalSms = "Thông báo: Quý khách đã chuyển tiền thành công tới số tài khoản 1234."
        val res1 = processIncomingSms("Techcombank", whitelistedNormalSms, mode, whitelist)
        assertTrue("Whitelisted sender SMS should be relayed in MODE_WHITELIST_ALL even without OTP", res1.shouldRelay)
        assertEquals("1234", res1.otpEvent?.otp)

        // 2. Sender NGOÀI whitelist gửi SMS thường -> BỊ TỪ CHỐI
        val nonWhitelistedNormalSms = "Thông báo từ cửa hàng: Đơn hàng số 5678 đã sẵn sàng giao."
        val res2 = processIncomingSms("UnknownStore", nonWhitelistedNormalSms, mode, whitelist)
        assertFalse("Non-whitelisted sender with normal SMS must be ignored in MODE_WHITELIST_ALL", res2.shouldRelay)

        // 3. Sender NGOÀI whitelist nhưng gửi tin nhắn chứa mã OTP hợp lệ -> VẪN ĐƯỢC NHẬN DIỆN
        val nonWhitelistedOtpSms = "Google: Your verification code is 445566."
        val res3 = processIncomingSms("Google", nonWhitelistedOtpSms, mode, whitelist)
        assertTrue("Authentic OTP must still be recognized even if sender is not in whitelist", res3.shouldRelay)
        assertEquals("445566", res3.otpEvent?.otp)
    }

    // ==========================================
    // 3. NHẬN DIỆN VÀ CHỐNG TRÙNG LẶP TIN NHẮN (DEDUPLICATION LOGIC)
    // ==========================================

    private class MemoryDeduplicator(private val ttlWindowMs: Long = 5 * 60 * 1000L) {
        private val recentHashes = mutableMapOf<String, Long>()

        private fun sha256(input: String): String {
            val md = MessageDigest.getInstance("SHA-256")
            val digest = md.digest(input.toByteArray(Charsets.UTF_8))
            return digest.joinToString("") { "%02x".format(it) }
        }

        @Synchronized
        fun isDuplicateAndRecord(sender: String, identifier: String, nowMs: Long = System.currentTimeMillis()): Boolean {
            val hash = sha256("$sender:$identifier")

            // Dọn dẹp các mục cũ quá TTL
            recentHashes.entries.removeIf { nowMs - it.value >= ttlWindowMs }

            if (recentHashes.containsKey(hash)) {
                return true // Đã tồn tại trong cửa sổ TTL -> trùng lặp
            }

            recentHashes[hash] = nowMs
            return false // Mới -> ghi nhận
        }
    }

    @Test
    fun testDeduplicationDropsImmediateDuplicateMessages() {
        val dedup = MemoryDeduplicator()
        val now = 1000000L

        // Lần đầu nhận OTP: không trùng
        val isDup1 = dedup.isDuplicateAndRecord("Viettel", "123456", now)
        assertFalse("First message should not be considered duplicate", isDup1)

        // Lần thứ hai nhận cùng người gửi và cùng OTP ngay sau đó: phải phát hiện trùng
        val isDup2 = dedup.isDuplicateAndRecord("Viettel", "123456", now + 1000)
        assertTrue("Identical message within TTL window must be flagged as duplicate", isDup2)
    }

    @Test
    fun testDeduplicationAllowsDifferentSendersOrDifferentOtps() {
        val dedup = MemoryDeduplicator()
        val now = 1000000L

        // Sender A với OTP 111111
        assertFalse(dedup.isDuplicateAndRecord("SenderA", "111111", now))

        // Sender B với cùng OTP 111111 -> Khác sender, hợp lệ!
        assertFalse("Same OTP from a different sender should NOT be flagged as duplicate",
            dedup.isDuplicateAndRecord("SenderB", "111111", now))

        // Sender A với OTP mới 222222 -> Cùng sender nhưng khác OTP, hợp lệ!
        assertFalse("New OTP from the same sender should NOT be flagged as duplicate",
            dedup.isDuplicateAndRecord("SenderA", "222222", now))
    }

    @Test
    fun testDeduplicationAllowsSameOtpAfterTtlExpires() {
        val ttlMs = 5 * 60 * 1000L // 5 minutes
        val dedup = MemoryDeduplicator(ttlMs)
        val initialTime = 1000000L

        // Lần đầu
        assertFalse(dedup.isDuplicateAndRecord("TPBank", "654321", initialTime))

        // 3 phút sau (vẫn trong cửa sổ TTL): bị chặn
        assertTrue(dedup.isDuplicateAndRecord("TPBank", "654321", initialTime + (3 * 60 * 1000L)))

        // 6 phút sau (vượt quá 5 phút TTL): cho phép gửi lại
        val afterTtlTime = initialTime + (6 * 60 * 1000L)
        assertFalse("Same OTP should be accepted after the 5-minute TTL window expires",
            dedup.isDuplicateAndRecord("TPBank", "654321", afterTtlTime))
    }
}
