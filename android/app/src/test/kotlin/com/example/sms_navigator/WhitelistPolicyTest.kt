package com.example.sms_navigator

import com.example.sms_navigator.policy.RelayDecision
import com.example.sms_navigator.policy.WhitelistEntry
import com.example.sms_navigator.policy.WhitelistMode
import com.example.sms_navigator.policy.WhitelistPolicy
import com.example.sms_navigator.util.OtpConfidence
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Phủ 100% ma trận quyết định của guard white-list (deny-by-default).
 */
class WhitelistPolicyTest {

    private fun entry(address: String, allowOtp: Boolean = false) = WhitelistEntry(address, allowOtp)

    private fun assertDrop(decision: RelayDecision, reason: String) {
        assertTrue("Expected Drop but got $decision", decision is RelayDecision.Drop)
        assertEquals(reason, (decision as RelayDecision.Drop).reason)
    }

    private fun assertAllow(decision: RelayDecision) {
        assertEquals(RelayDecision.Allow, decision)
    }

    // ==========================================
    // MODE_EXPLICIT
    // ==========================================

    @Test
    fun `explicit empty whitelist blocks everything`() {
        val decision = WhitelistPolicy.evaluate(
            WhitelistMode.EXPLICIT, emptyList(), "VCB", OtpConfidence.NONE
        )
        assertDrop(decision, WhitelistPolicy.REASON_WHITELIST_EMPTY)
    }

    @Test
    fun `explicit empty whitelist blocks otp from unknown sender`() {
        val decision = WhitelistPolicy.evaluate(
            WhitelistMode.EXPLICIT, emptyList(), "Google", OtpConfidence.CONFIRMED
        )
        assertDrop(decision, WhitelistPolicy.REASON_WHITELIST_EMPTY)
    }

    @Test
    fun `explicit unknown sender is blocked`() {
        val entries = listOf(entry("VCB"))
        assertDrop(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "GRAB", OtpConfidence.NONE),
            WhitelistPolicy.REASON_NOT_WHITELISTED
        )
        assertDrop(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "+12025550199", OtpConfidence.NONE),
            WhitelistPolicy.REASON_NOT_WHITELISTED
        )
    }

    @Test
    fun `explicit whitelisted without otp permission allows regular sms but blocks otp`() {
        val entries = listOf(entry("VCB", allowOtp = false))

        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "VCB", OtpConfidence.NONE)
        )
        assertDrop(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "VCB", OtpConfidence.CONFIRMED),
            WhitelistPolicy.REASON_OTP_NOT_ALLOWED
        )
    }

    @Test
    fun `explicit whitelisted with otp permission allows both`() {
        val entries = listOf(entry("VCB", allowOtp = true))

        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "VCB", OtpConfidence.NONE)
        )
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "VCB", OtpConfidence.CONFIRMED)
        )
    }

    @Test
    fun `explicit suspect treated as regular sms`() {
        val entries = listOf(entry("VCB", allowOtp = false))
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "VCB", OtpConfidence.SUSPECT)
        )
    }

    @Test
    fun `explicit any-match-wins for otp permission`() {
        val entries = listOf(
            entry("+8498", allowOtp = false),
            entry("+84987654321", allowOtp = true)
        )
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, entries, "+84987654321", OtpConfidence.CONFIRMED)
        )

        val reversed = listOf(
            entry("+84987654321", allowOtp = true),
            entry("+8498", allowOtp = false)
        )
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.EXPLICIT, reversed, "+84987654321", OtpConfidence.CONFIRMED)
        )
    }

    // ==========================================
    // MODE_ALL_ADDRESSES
    // ==========================================

    @Test
    fun `all-addresses allows regular sms from any sender with empty entries`() {
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, emptyList(), "GRAB", OtpConfidence.NONE)
        )
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, emptyList(), "+84901234567", OtpConfidence.NONE)
        )
    }

    @Test
    fun `all-addresses blocks confirmed otp without explicit entry`() {
        assertDrop(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, emptyList(), "VCB", OtpConfidence.CONFIRMED),
            WhitelistPolicy.REASON_OTP_NOT_ALLOWED
        )
    }

    @Test
    fun `all-addresses blocks suspected otp without explicit entry`() {
        assertDrop(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, emptyList(), "UnknownShop", OtpConfidence.SUSPECT),
            WhitelistPolicy.REASON_OTP_SUSPECTED
        )
    }

    @Test
    fun `all-addresses allows otp from explicitly ticked entry only`() {
        val entries = listOf(entry("VCB", allowOtp = true))

        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, entries, "VCB", OtpConfidence.CONFIRMED)
        )
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, entries, "VCB", OtpConfidence.SUSPECT)
        )

        assertDrop(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, entries, "MOMO", OtpConfidence.CONFIRMED),
            WhitelistPolicy.REASON_OTP_NOT_ALLOWED
        )
    }

    @Test
    fun `all-addresses entry without otp tick does not unlock otp`() {
        val entries = listOf(entry("MOMO", allowOtp = false))
        assertDrop(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, entries, "MOMO", OtpConfidence.CONFIRMED),
            WhitelistPolicy.REASON_OTP_NOT_ALLOWED
        )
    }

    @Test
    fun `all-addresses any-match-wins for otp permission`() {
        val entries = listOf(entry("VCB", allowOtp = false), entry("vcb", allowOtp = true))
        assertAllow(
            WhitelistPolicy.evaluate(WhitelistMode.ALL_ADDRESSES, entries, "VCB", OtpConfidence.CONFIRMED)
        )
    }
}
