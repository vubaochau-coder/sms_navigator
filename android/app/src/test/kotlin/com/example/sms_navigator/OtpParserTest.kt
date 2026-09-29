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
