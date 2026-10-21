package com.example.sms_navigator

import com.example.sms_navigator.data.KeyVault
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.data.ParkedMessage
import com.example.sms_navigator.data.RelayChannelSnapshot
import com.example.sms_navigator.data.RelayChannelStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** Identity vault: the JVM test runner has no Android Keystore. */
private object PlainVault : KeyVault {
    override fun encrypt(plaintext: String): String = "enc:$plaintext"
    override fun decrypt(blob: String): String = blob.removePrefix("enc:")
}

class RelayChannelStoreTest {

    private lateinit var otpPrefs: OtpPreferences
    private var now = 1_000_000L
    private lateinit var store: RelayChannelStore

    @Before
    fun setUp() {
        otpPrefs = OtpPreferences(FakeSharedPreferences())
        store = RelayChannelStore(otpPrefs, PlainVault) { now }
    }

    private fun snap(id: String, epoch: Long, key: String = "k-$id-$epoch") =
        RelayChannelSnapshot(channelId = id, name = "Kênh $id", epoch = epoch, keyBase64 = key)

    @Test
    fun `replaceAll keeps every owner channel, not just the first`() {
        store.replaceAll(listOf(snap("a", 1), snap("b", 3)))

        val all = store.all()
        assertEquals(listOf("a", "b"), all.map { it.channelId })
        assertEquals("k-a-1", store.get("a")?.activeKey)
        assertEquals("k-b-3", store.get("b")?.activeKey)
    }

    @Test
    fun `replaceAll drops channels no longer in the snapshot`() {
        store.replaceAll(listOf(snap("a", 1), snap("b", 1)))
        store.replaceAll(listOf(snap("b", 1)))

        assertNull(store.get("a"))
        assertEquals(1, store.all().size)
    }

    @Test
    fun `staged key is not used until promoted`() {
        store.replaceAll(listOf(snap("a", 2)))
        store.stageKey("a", null, 3, "k-a-3")

        val staged = store.get("a")!!
        assertEquals(2L, staged.activeEpoch)
        assertEquals(3L, staged.pendingEpoch)
        assertEquals("k-a-2", staged.activeKey)
        assertEquals("k-a-3", staged.keyFor(3))

        assertTrue(store.promoteKey("a", 3))
        val promoted = store.get("a")!!
        assertEquals(3L, promoted.activeEpoch)
        assertNull(promoted.pendingEpoch)
        assertEquals("k-a-3", promoted.activeKey)
    }

    @Test
    fun `promote fails without the key for that epoch`() {
        store.replaceAll(listOf(snap("a", 2)))
        assertFalse(store.promoteKey("a", 5))
        assertEquals(2L, store.get("a")!!.activeEpoch)
    }

    @Test
    fun `discard removes only the pending key`() {
        store.replaceAll(listOf(snap("a", 2)))
        store.stageKey("a", null, 3, "k-a-3")
        store.discardKey("a", 3)

        val channel = store.get("a")!!
        assertEquals(2L, channel.activeEpoch)
        assertNull(channel.pendingEpoch)
        assertNull(channel.keyFor(3))
        assertEquals("k-a-2", channel.activeKey)
    }

    @Test
    fun `replaceAll never downgrades an epoch that was already promoted`() {
        store.replaceAll(listOf(snap("a", 2)))
        store.stageKey("a", null, 3, "k-a-3")
        store.promoteKey("a", 3)

        // A reconcile that read the channel list just before the rotation
        store.replaceAll(listOf(snap("a", 2)))

        assertEquals(3L, store.get("a")!!.activeEpoch)
        assertEquals("k-a-3", store.get("a")!!.activeKey)
    }

    @Test
    fun `replaceAll keeps a pending key newer than the snapshot`() {
        store.replaceAll(listOf(snap("a", 2)))
        store.stageKey("a", null, 3, "k-a-3")

        store.replaceAll(listOf(snap("a", 2)))

        assertEquals(3L, store.get("a")!!.pendingEpoch)
        assertEquals("k-a-3", store.get("a")!!.keyFor(3))
    }

    @Test
    fun `old epochs are pruned to active plus one previous`() {
        store.replaceAll(listOf(snap("a", 1)))
        for (epoch in 2L..5L) {
            store.stageKey("a", null, epoch, "k-a-$epoch")
            store.promoteKey("a", epoch)
        }
        val channel = store.get("a")!!
        assertEquals(setOf(4L, 5L), channel.keys.keys)
    }

    @Test
    fun `keys are stored through the vault, never in plaintext`() {
        store.replaceAll(listOf(snap("a", 1, key = "SECRET")))
        val raw = otpPrefs.prefs.getString("relay_channels_v1", "")!!
        assertTrue(raw.contains("enc:SECRET"))
        assertFalse(raw.replace("enc:SECRET", "").contains("SECRET"))
    }

    @Test
    fun `migrates the legacy single active channel once`() {
        otpPrefs.activeChannelId = "legacy"
        otpPrefs.activeChannelName = "Kênh cũ"
        otpPrefs.activeChannelEpoch = 4L
        otpPrefs.activeChannelKeyBase64 = "legacy-key"

        val migrated = store.get("legacy")!!
        assertEquals(4L, migrated.activeEpoch)
        assertEquals("legacy-key", migrated.activeKey)
        assertEquals("Kênh cũ", migrated.name)
        assertNull(otpPrefs.activeChannelId)
    }

    @Test
    fun `parked messages drain once and expire after the TTL`() {
        store.park(ParkedMessage("m1", "a", "VCB", "OTP 123456", parkedAt = now))
        store.park(ParkedMessage("m2", "a", "VCB", "old", parkedAt = now - RelayChannelStore.PARKED_TTL_MS - 1))
        assertEquals(2, store.parkedCount())

        val drained = store.drainParked()
        assertEquals(listOf("m1"), drained.map { it.messageId })
        assertEquals("OTP 123456", drained.single().messageText)
        assertEquals(0, store.parkedCount())
    }

    @Test
    fun `replaceAll retains channels Dart could not resolve this run`() {
        store.replaceAll(listOf(snap("a", 2), snap("b", 1)))
        store.replaceAll(listOf(snap("b", 1)), retainIds = listOf("a"))

        assertEquals("k-a-2", store.get("a")?.activeKey)
        assertEquals(2, store.all().size)
    }

    // ------------------------------------------------------------- outbox (2.1)

    @Test
    fun `outbox stores SMS text and sender only through the vault`() {
        val id = store.putOutbox(ParkedMessage("m1", "a", "VCB", "Ma OTP 482913", parkedAt = now))

        assertEquals("a|m1", id)
        val raw = otpPrefs.prefs.getString("relay_outbox_v1", "")!!
        assertTrue(raw.contains("enc:Ma OTP 482913"))
        assertTrue(raw.contains("enc:VCB"))
        assertFalse(raw.replace("enc:Ma OTP 482913", "").contains("482913"))

        val back = store.getOutbox(id)!!
        assertEquals("Ma OTP 482913", back.messageText)
        assertEquals("VCB", back.sender)
        assertEquals("a", back.channelId)
        assertEquals("m1", back.messageId)
    }

    @Test
    fun `outbox entries are removed explicitly and keyed per channel`() {
        val a = store.putOutbox(ParkedMessage("m1", "a", "VCB", "x", parkedAt = now))
        val b = store.putOutbox(ParkedMessage("m1", "b", "VCB", "x", parkedAt = now))
        assertEquals(2, store.outboxCount())

        store.removeOutbox(a)
        assertNull(store.getOutbox(a))
        assertEquals("x", store.getOutbox(b)?.messageText)
    }

    @Test
    fun `outbox sweeps entries older than the TTL on write`() {
        store.putOutbox(ParkedMessage("old", "a", "VCB", "old", parkedAt = now - RelayChannelStore.PARKED_TTL_MS - 1))
        store.putOutbox(ParkedMessage("new", "a", "VCB", "new", parkedAt = now))

        assertEquals(1, store.outboxCount())
        assertNull(store.getOutbox("a|old"))
    }

    @Test
    fun `outbox is capped to the newest entries`() {
        for (i in 0 until RelayChannelStore.MAX_OUTBOX + 5) {
            store.putOutbox(ParkedMessage("m$i", "a", "VCB", "t$i", parkedAt = now))
        }
        assertEquals(RelayChannelStore.MAX_OUTBOX, store.outboxCount())
        assertNull(store.getOutbox("a|m0"))
        assertEquals("t${RelayChannelStore.MAX_OUTBOX + 4}", store.getOutbox("a|m${RelayChannelStore.MAX_OUTBOX + 4}")?.messageText)
    }
}
