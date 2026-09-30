package com.example.sms_navigator

import com.example.sms_navigator.util.OtpCrypto
import com.example.sms_navigator.util.OtpParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class OtpParserTest {

    // ==========================================
    // 1. CÚ PHÁP TIẾNG VIỆT (VIETNAMESE OTP)
    // ==========================================

    @Test
    fun testVietnameseStandardOtp() {
        val message = "Viettel: Ma OTP cua ban la 583921"
        val result = OtpParser.extractOtp("Viettel", message)

        assertNotNull(result)
        assertEquals("583921", result?.otp)
        assertEquals("Viettel", result?.sender)
    }

    @Test
    fun testVietnameseAccentedVerificationCode() {
        val message = "Mã xác thực của bạn là: 123456. Vui lòng không chia sẻ mã này cho bất kỳ ai."
        val result = OtpParser.extractOtp("TPBank", message)

        assertNotNull(result)
        assertEquals("123456", result?.otp)
        assertEquals("TPBank", result?.sender)
    }

    @Test
    fun testVietnameseUnaccentedMaXacThuc() {
        val message = "Techcombank: Ma xac thuc Smart OTP la 987654 cho giao dich chuyen khoan."
        val result = OtpParser.extractOtp("Techcombank", message)

        assertNotNull(result)
        assertEquals("987654", result?.otp)
    }

    @Test
    fun testVietnameseMaXacNhan() {
        val message = "Ma xac nhan thanh toan don hang cua ban la 445566, hieu luc trong 5 phut."
        val result = OtpParser.extractOtp("Shopee", message)

        assertNotNull(result)
        assertEquals("445566", result?.otp)
    }

    @Test
    fun testVietnameseOtpColonFormat() {
        val message = "Mã OTP: 789123 dùng để đăng nhập hệ thống VNeID."
        val result = OtpParser.extractOtp("VNeID", message)

        assertNotNull(result)
        assertEquals("789123", result?.otp)
    }

    // ==========================================
    // 2. CÚ PHÁP TIẾNG ANH (ENGLISH OTP)
    // ==========================================

    @Test
    fun testEnglishVerificationCode() {
        val message = "Your verification code is 821945"
        val result = OtpParser.extractOtp("Google", message)

        assertNotNull(result)
        assertEquals("821945", result?.otp)
        assertEquals("Google", result?.sender)
    }

    @Test
    fun testEnglishPasscodePattern() {
        val message = "Your Apple ID security passcode is 392810. Do not share it with anyone."
        val result = OtpParser.extractOtp("Apple", message)

        assertNotNull(result)
        assertEquals("392810", result?.otp)
    }

    @Test
    fun testEnglishOneTimePassword() {
        val message = "Your one time password (OTP) is 654321 for login to Binance."
        val result = OtpParser.extractOtp("Binance", message)

        assertNotNull(result)
        assertEquals("654321", result?.otp)
    }

    @Test
    fun testEnglishVerifyAccount() {
        val message = "Use code 998877 to verify your Telegram account."
        val result = OtpParser.extractOtp("Telegram", message)

        assertNotNull(result)
        assertEquals("998877", result?.otp)
    }

    @Test
    fun testEnglishSecurityCode() {
        val message = "PayPal: Your security code is 776655. It expires in 10 minutes."
        val result = OtpParser.extractOtp("PayPal", message)

        assertNotNull(result)
        assertEquals("776655", result?.otp)
    }

    // ==========================================
    // 3. CÚ PHÁP TIẾNG TRUNG (CHINESE SIMPLIFIED & TRADITIONAL)
    // ==========================================

    @Test
    fun testChineseForwardPatterns() {
        // Bank of Merchants (招商银行) - Forward 验证码
        val cmbMsg = "【招商银行】您的验证码是 849201，5分钟内有效，请勿泄露。"
        val res1 = OtpParser.extractOtp("95555", cmbMsg)
        assertNotNull(res1)
        assertEquals("849201", res1?.otp)
        assertEquals("95555", res1?.sender)

        // ICBC Dynamic Password (动态密码)
        val icbcMsg = "【中国工商银行】您正在办理网银转账，动态密码为 192837，切勿向他人泄露。"
        val res2 = OtpParser.extractOtp("95588", icbcMsg)
        assertNotNull(res2)
        assertEquals("192837", res2?.otp)

        // Alipay (支付宝) - 验证码：
        val alipayMsg = "【支付宝】验证码：749201，用于登录。任何人索取均为诈骗。"
        val res3 = OtpParser.extractOtp("Alipay", alipayMsg)
        assertNotNull(res3)
        assertEquals("749201", res3?.otp)

        // Pinduoduo (拼多多) - 校验码
        val pddMsg = "【拼多多】校验码 592018，有效时间5分钟。"
        val res4 = OtpParser.extractOtp("10695555", pddMsg)
        assertNotNull(res4)
        assertEquals("592018", res4?.otp)

        // Meituan (美团) - 短信口令
        val meituanMsg = "【美团】您的短信口令为 482910。"
        val res5 = OtpParser.extractOtp("Meituan", meituanMsg)
        assertNotNull(res5)
        assertEquals("482910", res5?.otp)

        // Bank of China (中国银行) - 动态口令
        val bocMsg = "【中国银行】动态口令 334455，您正在通过手机银行进行跨行汇款。"
        val res6 = OtpParser.extractOtp("95566", bocMsg)
        assertNotNull(res6)
        assertEquals("334455", res6?.otp)

        // Didi (滴滴出行) - 确认码
        val didiMsg = "【滴滴出行】您的确认码为 901234，用于手机验证。"
        val res7 = OtpParser.extractOtp("10690011", didiMsg)
        assertNotNull(res7)
        assertEquals("901234", res7?.otp)
    }

    @Test
    fun testChineseReversePatterns() {
        // Tencent (腾讯科技) - 849201（动态验证码）
        val tencentMsg = "【腾讯科技】849201（动态验证码），请在30分钟内填写。"
        val res1 = OtpParser.extractOtp("10690001", tencentMsg)
        assertNotNull(res1)
        assertEquals("849201", res1?.otp)

        // JD (京东) - 382910 为您的短信登录验证码
        val jdMsg = "【京东】382910 为您的短信登录验证码，请勿告知他人。"
        val res2 = OtpParser.extractOtp("10698888", jdMsg)
        assertNotNull(res2)
        assertEquals("382910", res2?.otp)

        // Taobao (淘宝) - 654321 是您的登录验证码
        val tbMsg = "【淘宝网】654321 是您的登录验证码，请在15分钟内输入。"
        val res3 = OtpParser.extractOtp("Taobao", tbMsg)
        assertNotNull(res3)
        assertEquals("654321", res3?.otp)
    }

    @Test
    fun testChineseTraditionalPatterns() {
        // Traditional Chinese: 認證碼 (Authentication code)
        val twMsg = "【台灣大哥大】您的認證碼為 678901，請於5分鐘內輸入，請勿提供給任何人。"
        val res1 = OtpParser.extractOtp("TaiwanMobile", twMsg)
        assertNotNull(res1)
        assertEquals("678901", res1?.otp)

        // Traditional Chinese: 動態密碼 (Dynamic password)
        val hkMsg = "【富邦銀行】動態密碼 123456，請於5分鐘內完成網上轉賬驗證。"
        val res2 = OtpParser.extractOtp("Fubon", hkMsg)
        assertNotNull(res2)
        assertEquals("123456", res2?.otp)

        // Traditional Chinese: 授權碼 (Authorization code)
        val shopeeTwMsg = "【蝦皮購物】您的授權碼為 887766，切勿提供給他人。"
        val res3 = OtpParser.extractOtp("ShopeeTW", shopeeTwMsg)
        assertNotNull(res3)
        assertEquals("887766", res3?.otp)
    }

    // ==========================================
    // 4. KIỂM THỬ ĐỘ DÀI OTP ĐA DẠNG (4 ĐẾN 8 KÝ TỰ SỐ)
    // ==========================================

    @Test
    fun testOtpLengthsFrom4To8Digits() {
        // 4 digits
        val res4 = OtpParser.extractOtp("Bank", "Your OTP code: 1234")
        assertNotNull(res4)
        assertEquals("1234", res4?.otp)

        // 5 digits
        val res5 = OtpParser.extractOtp("Bank", "Mã xác thực của bạn: 54321")
        assertNotNull(res5)
        assertEquals("54321", res5?.otp)

        // 6 digits
        val res6 = OtpParser.extractOtp("Bank", "Verification code: 123456")
        assertNotNull(res6)
        assertEquals("123456", res6?.otp)

        // 7 digits
        val res7 = OtpParser.extractOtp("Bank", "Your passcode is 7654321.")
        assertNotNull(res7)
        assertEquals("7654321", res7?.otp)

        // 8 digits
        val res8 = OtpParser.extractOtp("Bank", "【华为账号】动态验证码：87654321。")
        assertNotNull(res8)
        assertEquals("87654321", res8?.otp)
    }

    // ==========================================
    // 5. TIN NHẮN THẬT TỪ THIẾT BỊ (REAL-WORLD SMS SAMPLES)
    // ==========================================

    @Test
    fun testRealWorldQsmsEnglish() {
        val message = "[Qsms] Your verification code is 941749. For account safety, don't forward the code to others."
        val result = OtpParser.extractOtp("Qsms", message)

        assertNotNull(result)
        assertEquals("941749", result?.otp)
    }

    @Test
    fun testRealWorldChineseKingfa() {
        val message = "[金发科技]验证码为：856530，您正在登录，若非本人操作，请勿泄露。"
        val result = OtpParser.extractOtp("金发科技", message)

        assertNotNull(result)
        assertEquals("856530", result?.otp)
    }

    @Test
    fun testRealWorldSsoPrefixFormat() {
        val message = "490625 is your SSO's OTP"
        val result = OtpParser.extractOtp("SSO", message)

        assertNotNull(result)
        assertEquals("490625", result?.otp)
    }

    // ==========================================
    // 6. CÁC TRƯỜNG HỢP TIÊU CỰC VÀ BIÊN (NEGATIVE & EDGE CASES)
    // ==========================================

    @Test
    fun testDoNotMistakePhoneNumberForOtp() {
        // Lookaround (?<!\d)(\d{4,8})(?!\d) should NOT capture 10-11 digit phone numbers as OTP
        val msgWithPhone = "Quy khach vui long goi den tong dai 0987654321 de duoc ho tro."
        val result = OtpParser.extractOtp("Viettel", msgWithPhone)
        assertNull("Phone number must not be recognized as OTP", result)
    }

    @Test
    fun testDoNotMistakeBankAccountOrTransactionAmount() {
        val balanceMsg = "So du TK 0123456789 thay doi -500.000 VND vao 14:00."
        val result = OtpParser.extractOtp("VCB", balanceMsg)
        assertNull("Balance notification without OTP keywords must be ignored", result)
    }

    @Test
    fun testNonOtpPromotionsIgnored() {
        val promo1 = "Khuyen mai data 4G sieu toc chi 10k/ngay..."
        val result1 = OtpParser.extractOtp("Viettel", promo1)
        assertNull("Promotional message should be ignored", result1)

        val promo2 = "Ban da nap 100.000d vao tai khoan goi cuoc MI10D thanh cong."
        val result2 = OtpParser.extractOtp("195", promo2)
        assertNull("Balance top-up message should be ignored", result2)

        val promo3 = "Tai khoan cua ban vua dang nhap tu thiet bi la."
        val result3 = OtpParser.extractOtp("Bank", promo3)
        assertNull("Login notification without OTP should be ignored", result3)

        val chinesePromo = "全场5折大促销，点击链接领取优惠券，回T退订"
        val result4 = OtpParser.extractOtp("1069000", chinesePromo)
        assertNull("Chinese promo without OTP should be ignored", result4)
    }

    @Test
    fun testPromotionWithStrongOtpContextExtractedCorrectly() {
        // If a message has promotion words but also contains a strong OTP keyword like "mã xác thực" or "OTP"
        val mixedMsg = "Khuyen mai 20% khi nap tien qua app. Ma xac thuc OTP cua ban la 987654 de nhan qua."
        val result = OtpParser.extractOtp("Viettel", mixedMsg)

        assertNotNull("Should extract OTP even if message contains promotional text when strong OTP context is present", result)
        assertEquals("987654", result?.otp)
    }

    @Test
    fun testBlankOrEmptyMessageReturnsNull() {
        assertNull(OtpParser.extractOtp("Viettel", ""))
        assertNull(OtpParser.extractOtp("Viettel", "   "))
    }

    @Test
    fun testFindAnyDigits() {
        val bankNotification = "【中国建设银行】您尾号8888账户09月29日支出人民币1500元。"
        val digits = OtpParser.findAnyDigits(bankNotification)
        assertEquals("8888", digits)

        val noDigits = "欢迎使用中国移动服务！"
        assertNull(OtpParser.findAnyDigits(noDigits))
    }

    @Test
    fun testCryptoEncryptDecrypt() {
        val originalText = """{"sender":"Viettel","otp":"583921","timestamp":1759134000}"""
        // 32-byte dummy key
        val dummyKey = "12345678901234567890123456789012".toByteArray(Charsets.UTF_8)

        val encrypted = OtpCrypto.encrypt(originalText, dummyKey)
        assertNotNull(encrypted.ciphertextBase64)
        assertNotNull(encrypted.ivBase64)

        val decrypted = OtpCrypto.decrypt(encrypted.ciphertextBase64, encrypted.ivBase64, dummyKey)
        assertEquals(originalText, decrypted)
    }

    @Test
    fun testUserThreeOtpMessages() {
        // Message 1
        val msg1 = "[Qsms] Your verification code is 941749. For account safety, don't forward the code to others."
        val res1 = OtpParser.extractOtp("Qsms", msg1)
        assertNotNull("Message 1 must be detected", res1)
        assertEquals("941749", res1?.otp)

        // Message 2
        val msg2 = "[金发科技]验证码为：856530，您正在登录，若非本人操作，请勿泄露。"
        val res2 = OtpParser.extractOtp("金发科技", msg2)
        assertNotNull("Message 2 must be detected", res2)
        assertEquals("856530", res2?.otp)

        // Message 3
        val msg3 = "490625 is your SSO's OTP"
        val res3 = OtpParser.extractOtp("SSO", msg3)
        assertNotNull("Message 3 must be detected", res3)
        assertEquals("490625", res3?.otp)
    }
}
