package com.example.sms_navigator

import com.example.sms_navigator.policy.PhoneNormalizer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PhoneNormalizerTest {

    // ==========================================
    // CHUẨN HÓA SỐ (VN: +84 / 84 / 0084 / 0)
    // ==========================================

    @Test
    fun `normalize plus-84 to national form`() {
        assertEquals("0987654321", PhoneNormalizer.normalizeNumber("+84987654321"))
    }

    @Test
    fun `normalize bare 84 prefix to national form`() {
        assertEquals("0987654321", PhoneNormalizer.normalizeNumber("84987654321"))
    }

    @Test
    fun `normalize 0084 prefix to national form`() {
        assertEquals("0987654321", PhoneNormalizer.normalizeNumber("0084987654321"))
    }

    @Test
    fun `national number stays unchanged`() {
        assertEquals("0987654321", PhoneNormalizer.normalizeNumber("0987654321"))
    }

    @Test
    fun `short codes stay unchanged`() {
        assertEquals("6147", PhoneNormalizer.normalizeNumber("6147"))
        assertEquals("19001555", PhoneNormalizer.normalizeNumber("19001555"))
        assertEquals("10690001888", PhoneNormalizer.normalizeNumber("10690001888"))
    }

    @Test
    fun `separators are stripped before normalizing`() {
        assertEquals("0901234567", PhoneNormalizer.normalizeNumber("+84 90 123 4567"))
        assertEquals("0901234567", PhoneNormalizer.normalizeNumber("090-123-4567"))
        assertEquals("0901234567", PhoneNormalizer.normalizeNumber("+84 (90) 1234567"))
    }

    // ==========================================
    // SO KHỚP ĐẦU SỐ (EXACT SAU CHUẨN HÓA, KHÔNG CHẤP NHẬN PREFIX)
    // ==========================================

    @Test
    fun `entry full number matches sender in all VN formats`() {
        assertTrue(PhoneNormalizer.matches("+84987654321", "0987654321"))
        assertTrue(PhoneNormalizer.matches("84987654321", "0987654321"))
        assertTrue(PhoneNormalizer.matches("0987654321", "0987654321"))
        assertTrue(PhoneNormalizer.matches("+84 98 765 4321", "0987654321"))
    }

    @Test
    fun `entry in international form matches national sender`() {
        assertTrue(PhoneNormalizer.matches("0987654321", "+84987654321"))
        assertTrue(PhoneNormalizer.matches("0987654321", "84987654321"))
    }

    @Test
    fun `full number matches exactly`() {
        assertTrue(PhoneNormalizer.matches("+84987654321", "0987654321"))
        assertTrue(PhoneNormalizer.matches("0909123456", "0909123456"))
    }

    @Test
    fun `prefix matching is no longer accepted`() {
        assertFalse(PhoneNormalizer.matches("+84987654321", "098"))
        assertFalse(PhoneNormalizer.matches("0987654321", "+8498"))
        assertFalse(PhoneNormalizer.matches("10690001888", "1069"))
    }

    @Test
    fun `longer sender number does not match shorter entry`() {
        assertFalse(PhoneNormalizer.matches("09876543210", "0987654321"))
        assertFalse(PhoneNormalizer.matches("0987654321x", "0987654321"))
    }

    @Test
    fun `different numbers do not match`() {
        assertFalse(PhoneNormalizer.matches("+12025550199", "+8613800138000"))
        assertFalse(PhoneNormalizer.matches("0912345678", "0901234567"))
        assertFalse(PhoneNormalizer.matches("08680001888", "10690001888"))
    }

    @Test
    fun `enterprise gateway number matches exactly`() {
        assertTrue(PhoneNormalizer.matches("10690001888", "10690001888"))
        assertFalse(PhoneNormalizer.matches("1069000188", "10690001888"))
    }

    @Test
    fun `punctuation in sender and entry both normalized`() {
        assertTrue(PhoneNormalizer.matches("+84 (90) 1234567", "+84901234567"))
        assertTrue(PhoneNormalizer.matches("090-123-4567", "0901234567"))
    }

    // ==========================================
    // SO KHỚP BRANDNAME (EXACT, PHÂN BIỆT HOA THƯỜNG)
    // ==========================================

    @Test
    fun `brandname matches case-sensitively`() {
        assertTrue(PhoneNormalizer.matches("TPBank", "TPBank"))
        assertFalse(PhoneNormalizer.matches("tpbank", "TPBank"))
        assertFalse(PhoneNormalizer.matches("TPBANK", "TPBank"))
        assertFalse(PhoneNormalizer.matches("Viettel", "viettel"))
    }

    @Test
    fun `brandname with surrounding separators matches after cleaning`() {
        assertTrue(PhoneNormalizer.matches(" VCB ", "VCB"))
        assertFalse(PhoneNormalizer.matches("VCBPROMO", "VCB"))
    }

    @Test
    fun `brandname is exact match to prevent spoofing`() {
        assertFalse(PhoneNormalizer.matches("VCB_PROMO", "VCB"))
        assertFalse(PhoneNormalizer.matches("Vietcombank", "Viettel"))
        assertFalse(PhoneNormalizer.matches("MOMO_FAKE", "MOMO"))
    }

    @Test
    fun `unicode brandname matches exactly`() {
        assertTrue(PhoneNormalizer.matches("招商银行", "招商银行"))
        assertFalse(PhoneNormalizer.matches("招商银行促销", "招商银行"))
    }

    @Test
    fun `blank sender or entry never matches`() {
        assertFalse(PhoneNormalizer.matches("", "VCB"))
        assertFalse(PhoneNormalizer.matches("VCB", ""))
        assertFalse(PhoneNormalizer.matches("  ", "VCB"))
    }
}
