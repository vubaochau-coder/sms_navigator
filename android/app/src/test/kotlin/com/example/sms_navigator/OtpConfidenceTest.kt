package com.example.sms_navigator

import com.example.sms_navigator.util.OtpConfidence
import com.example.sms_navigator.util.OtpParser
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Phân loại độ tin cậy OTP cho guard white-list:
 * - CONFIRMED: keyword xác thực + mã theo ngữ cảnh chặt.
 * - SUSPECT: keyword xác thực + chuỗi số nhưng không theo ngữ cảnh chặt.
 * - NONE: SMS thường — kể cả khi chứa số (mã đơn hàng, số tiền, số tài khoản).
 */
class OtpConfidenceTest {

    @After
    fun tearDown() {
        OtpParser.DIGITS_ONLY_SUSPECT = false
    }

    // ==========================================
    // CONFIRMED
    // ==========================================

    @Test
    fun `vietnamese verification code is confirmed`() {
        assertEquals(
            OtpConfidence.CONFIRMED,
            OtpParser.classifyConfidence("Mã xác thực của bạn là 123456.")
        )
    }

    @Test
    fun `english verification code is confirmed`() {
        assertEquals(
            OtpConfidence.CONFIRMED,
            OtpParser.classifyConfidence("Google: Your verification code is 445566.")
        )
    }

    @Test
    fun `explicit otp keyword is confirmed`() {
        assertEquals(
            OtpConfidence.CONFIRMED,
            OtpParser.classifyConfidence("Ma OTP: 123456")
        )
    }

    @Test
    fun `chinese reverse layout is confirmed`() {
        assertEquals(
            OtpConfidence.CONFIRMED,
            OtpParser.classifyConfidence("849201（动态验证码）")
        )
    }

    @Test
    fun `code before keyword is confirmed`() {
        assertEquals(
            OtpConfidence.CONFIRMED,
            OtpParser.classifyConfidence("123456 la ma xac thuc cua ban")
        )
    }

    @Test
    fun `no digits means not confirmed`() {
        assertEquals(
            OtpConfidence.NONE,
            OtpParser.classifyConfidence("Vui lòng nhấn vào link để xác thực tài khoản.")
        )
    }

    // ==========================================
    // NONE — SMS thường chứa số KHÔNG được coi là OTP
    // ==========================================

    @Test
    fun `order code with generic ma word is not otp`() {
        assertEquals(
            OtpConfidence.NONE,
            OtpParser.classifyConfidence("Mã đơn hàng GH-452319 của bạn đã được giao.")
        )
    }

    @Test
    fun `bank balance notification is not otp`() {
        assertEquals(
            OtpConfidence.NONE,
            OtpParser.classifyConfidence("Tài khoản 9876 biến động -500,000 VND.")
        )
    }

    @Test
    fun `order id with digits only is not otp`() {
        assertEquals(
            OtpConfidence.NONE,
            OtpParser.classifyConfidence("Đơn #456123 đã sẵn sàng giao.")
        )
    }

    @Test
    fun `generic code word without verification context is not otp`() {
        assertEquals(
            OtpConfidence.NONE,
            OtpParser.classifyConfidence("Promo code 123456 for your next order!")
        )
    }

    @Test
    fun `blank body is none`() {
        assertEquals(OtpConfidence.NONE, OtpParser.classifyConfidence(""))
        assertEquals(OtpConfidence.NONE, OtpParser.classifyConfidence("   "))
    }

    // ==========================================
    // SUSPECT
    // ==========================================

    @Test
    fun `verification keyword with distant digits is suspect`() {
        assertEquals(
            OtpConfidence.SUSPECT,
            OtpParser.classifyConfidence("He thong xac thuc dang bao tri. Ma so ho so cua ban la 452319, vui long luu y.")
        )
    }

    @Test
    fun `otp keyword with unrelated digits is suspect`() {
        assertEquals(
            OtpConfidence.SUSPECT,
            OtpParser.classifyConfidence("Ban da dang ky OTP cho dich vu moi, tham chieu 778899.")
        )
    }

    @Test
    fun `digits-only suspect knob`() {
        try {
            OtpParser.DIGITS_ONLY_SUSPECT = true
            assertEquals(
                OtpConfidence.SUSPECT,
                OtpParser.classifyConfidence("Đơn #456123 đã sẵn sàng giao.")
            )
        } finally {
            OtpParser.DIGITS_ONLY_SUSPECT = false
        }
        assertEquals(
            OtpConfidence.NONE,
            OtpParser.classifyConfidence("Đơn #456123 đã sẵn sàng giao.")
        )
    }
}
