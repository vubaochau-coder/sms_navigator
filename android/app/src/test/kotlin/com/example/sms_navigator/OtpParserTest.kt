package com.example.sms_navigator

import com.example.sms_navigator.util.OtpCrypto
import com.example.sms_navigator.util.OtpParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Base64

class OtpParserTest {

    @Test
    fun testViettelOtpExtraction() {
        val message = "Viettel: Ma OTP cua ban la 583921"
        val result = OtpParser.extractOtp("Viettel", message)

        assertNotNull(result)
        assertEquals("583921", result?.otp)
        assertEquals("Viettel", result?.sender)
    }

    @Test
    fun testEnglishVerificationCode() {
        val message = "Your verification code is 821945"
        val result = OtpParser.extractOtp("Google", message)

        assertNotNull(result)
        assertEquals("821945", result?.otp)
        assertEquals("Google", result?.sender)
    }

    @Test
    fun testChineseOtpExtraction() {
        // Case 1: Standard forward pattern (Bank of Merchants / 招商银行)
        val cmbMsg = "【招商银行】您的验证码是 849201，5分钟内有效，请勿泄露。"
        val res1 = OtpParser.extractOtp("95555", cmbMsg)
        assertNotNull(res1)
        assertEquals("849201", res1?.otp)
        assertEquals("95555", res1?.sender)

        // Case 2: ICBC Dynamic Password (动态密码)
        val icbcMsg = "【中国工商银行】您正在办理网银转账，动态密码为 192837，切勿向他人泄露。"
        val res2 = OtpParser.extractOtp("95588", icbcMsg)
        assertNotNull(res2)
        assertEquals("192837", res2?.otp)

        // Case 3: Reverse pattern with parentheses (Tencent / 动态验证码)
        val tencentMsg = "【腾讯科技】849201（动态验证码），请在30分钟内填写。"
        val res3 = OtpParser.extractOtp("10690001", tencentMsg)
        assertNotNull(res3)
        assertEquals("849201", res3?.otp)

        // Case 4: Reverse pattern with "为您的短信登录验证码" (JD / 京东)
        val jdMsg = "【京东】382910 为您的短信登录验证码，请勿告知他人。"
        val res4 = OtpParser.extractOtp("10698888", jdMsg)
        assertNotNull(res4)
        assertEquals("382910", res4?.otp)

        // Case 5: Alipay (支付宝)
        val alipayMsg = "【支付宝】验证码：749201，用于登录。任何人索取均为诈骗。"
        val res5 = OtpParser.extractOtp("Alipay", alipayMsg)
        assertNotNull(res5)
        assertEquals("749201", res5?.otp)

        // Case 6: Jiao yan ma (校验码)
        val pddMsg = "【拼多多】校验码 592018，有效时间5分钟。"
        val res6 = OtpParser.extractOtp("10695555", pddMsg)
        assertNotNull(res6)
        assertEquals("592018", res6?.otp)

        // Case 7: SMS token (短信口令)
        val meituanMsg = "【美团】您的短信口令为 482910。"
        val res7 = OtpParser.extractOtp("Meituan", meituanMsg)
        assertNotNull(res7)
        assertEquals("482910", res7?.otp)
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
    fun testNonOtpPromotionsIgnored() {
        val promo1 = "Khuyen mai data 4G sieu toc chi 10k/ngay..."
        val result1 = OtpParser.extractOtp("Viettel", promo1)
        assertNull("Promotional message should be ignored", result1)

        val promo2 = "Ban da nap 100.000d vao tai khoan."
        val result2 = OtpParser.extractOtp("195", promo2)
        assertNull("Balance top-up message should be ignored", result2)

        val promo3 = "Tai khoan cua ban vua dang nhap."
        val result3 = OtpParser.extractOtp("Bank", promo3)
        assertNull("Login notification without OTP should be ignored", result3)

        val chinesePromo = "全场5折大促销，点击链接领取优惠券，回T退订"
        val result4 = OtpParser.extractOtp("1069000", chinesePromo)
        assertNull("Chinese promo without OTP should be ignored", result4)
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
}
