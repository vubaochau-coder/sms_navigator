package com.example.sms_navigator

import com.example.sms_navigator.model.OtpEvent
import com.example.sms_navigator.policy.RelayDecision
import com.example.sms_navigator.policy.WhitelistEntry
import com.example.sms_navigator.policy.WhitelistMode
import com.example.sms_navigator.policy.WhitelistPolicy
import com.example.sms_navigator.policy.PhoneNormalizer
import com.example.sms_navigator.util.OtpParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.MessageDigest

/**
 * Kiểm thử tầng Java/Kotlin native cho nghiệp vụ Nhận Diện Tin Nhắn:
 * - Nhận diện người gửi theo Whitelist (đầu số, brandname, chuẩn hóa +84/84/0).
 * - Ra quyết định relay theo WhitelistPolicy (deny-by-default, quyền OTP per-address).
 * - Nhận diện và lọc trùng lặp tin nhắn (Deduplication & Replay attack prevention).
 */
class MessageRecognitionTest {

    // ==========================================
    // 1. NHẬN DIỆN NGƯỜI GỬI THEO WHITELIST (SENDER WHITELIST RECOGNITION)
    // ==========================================

    @Test
    fun testRecognizeSenderByInternationalPrefix() {
        // Whitelist cấu hình đầu số Trung Quốc (+86, 1069) và đầu số Việt Nam (+84, 090)
        val whitelist = listOf("+86", "1069", "+84", "090")

        // Đầu số Trung Quốc
        assertTrue("Should recognize China international prefix +86",
            PhoneNormalizer.matches("+8613800138000", "+86"))
        assertTrue("Should recognize China enterprise SMS gateway 1069",
            PhoneNormalizer.matches("10690001888", "1069"))

        // Đầu số Việt Nam
        assertTrue("Should recognize Vietnam international prefix +84",
            PhoneNormalizer.matches("+84987654321", "+84"))
        assertTrue("Should recognize domestic prefix 090",
            PhoneNormalizer.matches("0909123456", "090"))

        // Đầu số không thuộc whitelist
        val usaSender = "+12025550199"
        assertFalse("Should reject non-whitelisted USA sender",
            whitelist.any { PhoneNormalizer.matches(usaSender, it) })

        // Whitelist chỉ chứa "090" -> đầu số 091 bị từ chối
        assertFalse("Should reject non-whitelisted prefix 091",
            PhoneNormalizer.matches("0912345678", "090"))

        // Ngược lại, whitelist "+84" phủ mọi số VN sau chuẩn hóa (kể cả 091...)
        assertTrue("Entry +84 covers all Vietnamese numbers after normalization",
            PhoneNormalizer.matches("0912345678", "+84"))
    }

    @Test
    fun testRecognizeSenderByBrandname() {
        assertTrue("Should recognize brandname Viettel", PhoneNormalizer.matches("Viettel", "Viettel"))
        assertTrue("Should recognize brandname TPBank case-insensitively", PhoneNormalizer.matches("tpbank", "TPBank"))
        assertTrue("Should recognize brandname Alipay", PhoneNormalizer.matches("Alipay", "Alipay"))
        assertTrue("Should recognize brandname WeChat", PhoneNormalizer.matches("WeChat", "WeChat"))
        assertTrue("Should recognize Chinese brandname 招商银行", PhoneNormalizer.matches("招商银行", "招商银行"))

        assertFalse("Should reject unknown brandname Vietcombank", PhoneNormalizer.matches("Vietcombank", "Viettel"))
        assertFalse("Should reject spam brandname LoanNow", PhoneNormalizer.matches("LoanNow", "LoanNow2"))
    }

    @Test
    fun testRecognizeSenderWithPunctuationAndSpacing() {
        // Số điện thoại chứa dấu ngoặc đơn, gạch ngang, dấu cách
        assertTrue("Should recognize normalized phone number with spaces",
            PhoneNormalizer.matches("+84 90 123 4567", "+8490"))
        assertTrue("Should recognize normalized phone number with dashes",
            PhoneNormalizer.matches("090-123-4567", "0901234567"))
        assertTrue("Should recognize normalized phone number with parentheses",
            PhoneNormalizer.matches("+84 (90) 1234567", "+8490"))
    }

    // ==========================================
    // 2. RA QUYẾT ĐỊNH RELAY THEO WHITELIST POLICY (DENY-BY-DEFAULT)
    // ==========================================

    data class RecognitionResult(
        val shouldRelay: Boolean,
        val otpEvent: OtpEvent?,
        val reason: String
    )

    /**
     * Mô phỏng logic ra quyết định trong SmsReceiver sau khi áp dụng WhitelistPolicy.
     */
    private fun processIncomingSms(
        sender: String,
        messageText: String,
        mode: WhitelistMode,
        entries: List<WhitelistEntry>
    ): RecognitionResult {
        val confidence = OtpParser.classifyConfidence(messageText)
        return when (val decision = WhitelistPolicy.evaluate(mode, entries, sender, confidence)) {
            is RelayDecision.Drop -> RecognitionResult(
                shouldRelay = false,
                otpEvent = null,
                reason = decision.reason
            )
            RelayDecision.Allow -> {
                val otpEvent = OtpParser.extractOtp(sender, messageText)
                    ?: OtpEvent(
                        sender = sender,
                        otp = OtpParser.findAnyDigits(messageText) ?: "SMS",
                        fullMessage = messageText
                    )
                RecognitionResult(shouldRelay = true, otpEvent = otpEvent, reason = "Allowed by whitelist policy")
            }
        }
    }

    @Test
    fun testExplicitWhitelistDenyByDefault() {
        val mode = WhitelistMode.EXPLICIT
        val entries = listOf(WhitelistEntry("TPBank", allowOtp = false))

        // 1. Whitelist trống -> chặn TẤT CẢ, kể cả OTP
        val emptyResult = processIncomingSms("TPBank", "Mã xác thực của bạn là 123456.", mode, emptyList())
        assertFalse("Empty whitelist must block everything", emptyResult.shouldRelay)
        assertEquals(WhitelistPolicy.REASON_WHITELIST_EMPTY, emptyResult.reason)

        // 2. Sender trong whitelist nhưng CHƯA tick OTP -> OTP bị chặn (an toàn mặc định)
        val otpBlocked = processIncomingSms("TPBank", "Mã xác thực của bạn là 123456.", mode, entries)
        assertFalse("OTP must be blocked when allow_otp is false", otpBlocked.shouldRelay)
        assertEquals(WhitelistPolicy.REASON_OTP_NOT_ALLOWED, otpBlocked.reason)
        assertNull(otpBlocked.otpEvent)

        // 3. Sau khi tick "Cho phép gửi OTP" -> OTP được relay
        val ticked = listOf(WhitelistEntry("TPBank", allowOtp = true))
        val otpAllowed = processIncomingSms("TPBank", "Mã xác thực của bạn là 123456.", mode, ticked)
        assertTrue("Ticked OTP permission must relay the OTP", otpAllowed.shouldRelay)
        assertEquals("123456", otpAllowed.otpEvent?.otp)

        // 4. Sender trong whitelist, SMS thường -> relay full SMS dù không tick OTP
        val normalSms = "Cảm ơn quý khách đã mua sắm tại cửa hàng. Hẹn gặp lại quý khách!"
        val normalAllowed = processIncomingSms("TPBank", normalSms, mode, entries)
        assertTrue("Whitelisted sender's regular SMS must be relayed", normalAllowed.shouldRelay)
        assertEquals("SMS", normalAllowed.otpEvent?.otp)

        // 5. Sender ngoài whitelist -> chặn mọi loại tin
        val unknown = processIncomingSms("UnknownStore", "Đơn hàng số 5678 đã sẵn sàng giao.", mode, entries)
        assertFalse("Non-whitelisted sender must be blocked", unknown.shouldRelay)
        assertEquals(WhitelistPolicy.REASON_NOT_WHITELISTED, unknown.reason)
    }

    @Test
    fun testAllAddressesModeBlocksOtpWithoutExplicitEntry() {
        val mode = WhitelistMode.ALL_ADDRESSES
        val emptyEntries = emptyList<WhitelistEntry>()

        // 1. SMS thường từ bất kỳ đầu số nào -> relay
        val bankSms = "Tài khoản 9876 biến động -500,000 VND."
        val bankAllowed = processIncomingSms("VCB", bankSms, mode, emptyEntries)
        assertTrue("Regular SMS from any address must be relayed in ALL_ADDRESSES", bankAllowed.shouldRelay)
        assertEquals("9876", bankAllowed.otpEvent?.otp)

        val textOnlySms = "Chúc bạn một ngày tốt lành và nhiều may mắn!"
        val textAllowed = processIncomingSms("Friend", textOnlySms, mode, emptyEntries)
        assertTrue("Text-only SMS must be relayed with 'SMS' tag", textAllowed.shouldRelay)
        assertEquals("SMS", textAllowed.otpEvent?.otp)

        // 2. OTP từ đầu số KHÔNG được tick -> chặn (không chấp nhận all-in OTP)
        val otpSms = "Mã OTP là 998877."
        val otpBlocked = processIncomingSms("Viettel", otpSms, mode, emptyEntries)
        assertFalse("OTP must NOT be relayed all-in in ALL_ADDRESSES mode", otpBlocked.shouldRelay)
        assertEquals(WhitelistPolicy.REASON_OTP_NOT_ALLOWED, otpBlocked.reason)

        // 3. Chỉ khi chủ động tick từng address thì OTP mới đi được
        val ticked = listOf(WhitelistEntry("Viettel", allowOtp = true))
        val otpAllowed = processIncomingSms("Viettel", otpSms, mode, ticked)
        assertTrue("Explicitly ticked address must relay OTP", otpAllowed.shouldRelay)
        assertEquals("998877", otpAllowed.otpEvent?.otp)

        // 4. Address khác vẫn bị chặn OTP
        val otherBlocked = processIncomingSms("MOMO", otpSms, mode, ticked)
        assertFalse("Other addresses must remain blocked for OTP", otherBlocked.shouldRelay)
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
