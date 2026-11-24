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
    fun `cooldown is shared across gate instances and expires`() {
        val prefs = FakeSharedPreferences()
        var now = 1_000_000L
        var pings = 0
        var awake = false
        fun gate() = ServerWakeGate(prefs, clock = { now }, ping = { pings++; awake })

        assertFalse(gate().wake())
        now += 30_000L
        assertFalse(gate().wake()) // within cooldown: cached failure, no ping
        assertEquals(1, pings)

        now += ServerWakeGate.COOLDOWN_MS
        awake = true
        assertTrue(gate().wake())
        assertEquals(2, pings)
    }

    @Test
    fun `a throwing ping counts as not awake`() {
        val gate = ServerWakeGate(FakeSharedPreferences(), clock = { 1L }, ping = { error("boom") })
        assertFalse(gate.wake())
    }
}
