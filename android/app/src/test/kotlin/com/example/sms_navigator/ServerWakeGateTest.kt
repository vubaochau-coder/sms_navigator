package com.example.sms_navigator

import com.example.sms_navigator.worker.ServerWakeGate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ServerWakeGateTest {

    @Test
    fun `challenge HTML and Render plain-text 429 are edge blocks`() {
        assertTrue(ServerWakeGate.isEdgeBlocked(429, "<!DOCTYPE html><title>Just a moment...</title>"))
        assertTrue(ServerWakeGate.isEdgeBlocked(429, "Too Many Requests"))
        assertTrue(ServerWakeGate.isEdgeBlocked(503, null))
    }

    @Test
    fun `server JSON envelopes and other statuses are not edge blocks`() {
        assertFalse(ServerWakeGate.isEdgeBlocked(429, """{"success":false,"error":"RATE_LIMITED"}"""))
        assertFalse(ServerWakeGate.isEdgeBlocked(403, """{"success":false,"error":"FORBIDDEN"}"""))
        assertFalse(ServerWakeGate.isEdgeBlocked(400, "<html>bad</html>"))
        assertFalse(ServerWakeGate.isEdgeBlocked(500, "<html>oops</html>"))
    }

    @Test
    fun `polls through the hibernation 429s until the server is healthy`() {
        var now = 0L
        var pings = 0
        val gate = ServerWakeGate(
            FakeSharedPreferences(),
            clock = { now },
            ping = { pings++; pings >= 4 }, // asleep for 3 pings
            sleep = { now += it },
        )
        assertTrue(gate.wake())
        assertEquals(4, pings)
        assertEquals(3_000L + 5_000L + 8_000L, now)
    }

    @Test
    fun `gives up at the deadline`() {
        var now = 0L
        var pings = 0
        val gate = ServerWakeGate(FakeSharedPreferences(), clock = { now }, ping = { pings++; false }, sleep = { now += it })
        assertFalse(gate.wake())
        assertTrue(now < ServerWakeGate.WAKE_DEADLINE_MS)
        assertTrue(pings > 5)
    }

    @Test
    fun `cooldown is shared across gate instances and expires`() {
        val prefs = FakeSharedPreferences()
        var now = 1_000_000L
        var pings = 0
        var awake = false
        fun gate() = ServerWakeGate(prefs, clock = { now }, ping = { pings++; awake }, sleep = { now += it })

        assertFalse(gate().wake())
        val pingsAfterFirst = pings
        now += 10_000L
        assertFalse(gate().wake()) // within failure cooldown: cached, no ping
        assertEquals(pingsAfterFirst, pings)

        now += ServerWakeGate.FAILURE_COOLDOWN_MS
        awake = true
        assertTrue(gate().wake())
        assertEquals(pingsAfterFirst + 1, pings)
    }

    @Test
    fun `a throwing ping counts as not awake`() {
        var now = 1L
        val gate = ServerWakeGate(FakeSharedPreferences(), clock = { now }, ping = { error("boom") }, sleep = { now += it })
        assertFalse(gate.wake())
    }
}
