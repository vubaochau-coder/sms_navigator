package com.example.sms_navigator

import com.example.sms_navigator.data.KeyVault
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.data.ParkedMessage
import com.example.sms_navigator.data.RelayChannelSnapshot
import com.example.sms_navigator.data.RelayChannelStore
import com.example.sms_navigator.data.VaultFallbackLog
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Keystore that is always broken (some ROMs). */
private object BrokenVault : KeyVault {
    override fun encrypt(plaintext: String): String = throw IllegalStateException("keystore unavailable")
    override fun decrypt(blob: String): String = throw IllegalStateException("keystore unavailable")
}

class VaultFallbackLogTest {

    @Test
    fun `a broken keystore keeps relaying but every plaintext write is recorded`() {
        val prefs = FakeSharedPreferences()
        val store = RelayChannelStore(OtpPreferences(prefs), BrokenVault) { 1_000L }

        store.replaceAll(listOf(RelayChannelSnapshot("a", "Kênh", 1, "key-a")))
        val outboxId = store.putOutbox(ParkedMessage("m1", "a", "VCB", "OTP 123456", parkedAt = 1_000L))

        // Fail-open: still usable
        assertEquals("key-a", store.get("a")?.activeKey)
        assertEquals("OTP 123456", store.getOutbox(outboxId)?.messageText)

        val report = VaultFallbackLog.snapshot(prefs)!!
        assertTrue((report["count"] as Int) >= 3) // channel key, sender, text
        assertEquals("relay_store", report["site"])
        assertTrue((report["error"] as String).contains("keystore unavailable"))
    }

    @Test
    fun `no report without failures, and clear resets it`() {
        val prefs = FakeSharedPreferences()
        assertNull(VaultFallbackLog.snapshot(prefs))

        VaultFallbackLog.record(prefs, "device_token", RuntimeException("boom"), now = 42L)
        assertEquals(42L, VaultFallbackLog.snapshot(prefs)!!["at"])

        VaultFallbackLog.clear(prefs)
        assertNull(VaultFallbackLog.snapshot(prefs))
    }
}
