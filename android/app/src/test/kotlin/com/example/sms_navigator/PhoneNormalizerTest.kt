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
    // SO KHỚP ĐẦU SỐ (PREFIX, ĐA DẠNG ĐỊNH DẠNG)
    // ==========================================

    @Test
    fun `entry 098 matches sender in all VN formats`() {
        assertTrue(PhoneNormalizer.matches("+84987654321", "098"))
        assertTrue(PhoneNormalizer.matches("84987654321", "098"))
        assertTrue(PhoneNormalizer.matches("0987654321", "098"))
        assertTrue(PhoneNormalizer.matches("+84 98 765 4321", "098"))
    }

    @Test
    fun `entry in international form matches national sender`() {
        assertTrue(PhoneNormalizer.matches("0987654321", "+8498"))
        assertTrue(PhoneNormalizer.matches("0987654321", "8498"))
    }

    @Test
    fun `full number matches exactly`() {
        assertTrue(PhoneNormalizer.matches("+84987654321", "0987654321"))
        assertTrue(PhoneNormalizer.matches("0909123456", "0909123456"))
    }

    @Test
    fun `different prefixes do not match`() {
        assertFalse(PhoneNormalizer.matches("+12025550199", "+86"))
        assertFalse(PhoneNormalizer.matches("0912345678", "090"))
        assertFalse(PhoneNormalizer.matches("08680001888", "1069"))
    }

    @Test
    fun `enterprise gateway prefix matches`() {
        assertTrue(PhoneNormalizer.matches("10690001888", "1069"))
    }

    @Test
    fun `punctuation in sender and entry both normalized`() {
        assertTrue(PhoneNormalizer.matches("+84 (90) 1234567", "+8490"))
        assertTrue(PhoneNormalizer.matches("090-123-4567", "0901234567"))
    }

    // ==========================================
    // SO KHỚP BRANDNAME (EXACT, KHÔNG PHÂN BIỆT HOA THƯỜNG)
    // ==========================================

    @Test
    fun `brandname matches case-insensitively`() {
        assertTrue(PhoneNormalizer.matches("tpbank", "TPBank"))
        assertTrue(PhoneNormalizer.matches("TPBANK", "TPBank"))
        assertTrue(PhoneNormalizer.matches("Viettel", "viettel"))
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
