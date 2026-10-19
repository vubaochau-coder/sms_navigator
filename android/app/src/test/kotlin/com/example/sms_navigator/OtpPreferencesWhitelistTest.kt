package com.example.sms_navigator
import android.content.SharedPreferences
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.policy.WhitelistEntry
import com.example.sms_navigator.policy.WhitelistMode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class FakeSharedPreferences : SharedPreferences {
    private val data = mutableMapOf<String, Any>()

    override fun getAll(): MutableMap<String, *> = HashMap(data)
    override fun getString(key: String?, defValue: String?): String? = data[key] as? String ?: defValue
    override fun getStringSet(key: String?, defValues: MutableSet<String>?): MutableSet<String>? =
        @Suppress("UNCHECKED_CAST") (data[key] as? MutableSet<String>) ?: defValues
    override fun getInt(key: String?, defValue: Int): Int = (data[key] as? Number)?.toInt() ?: defValue
    override fun getLong(key: String?, defValue: Long): Long = (data[key] as? Number)?.toLong() ?: defValue
    override fun getFloat(key: String?, defValue: Float): Float = (data[key] as? Number)?.toFloat() ?: defValue
    override fun getBoolean(key: String?, defValue: Boolean): Boolean = data[key] as? Boolean ?: defValue
    override fun contains(key: String?): Boolean = data.containsKey(key)

    override fun edit(): SharedPreferences.Editor = FakeEditor(data)
    override fun registerOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener?) {}
    override fun unregisterOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener?) {}

    class FakeEditor(private val backing: MutableMap<String, Any>) : SharedPreferences.Editor {
        private val temp = mutableMapOf<String, Any?>()
        private var clearRequested = false

        override fun putString(key: String?, value: String?): SharedPreferences.Editor {
            if (key != null) temp[key] = value
            return this
        }
        override fun putStringSet(key: String?, values: MutableSet<String>?): SharedPreferences.Editor {
            if (key != null) temp[key] = values
            return this
        }
        override fun putInt(key: String?, value: Int): SharedPreferences.Editor {
            if (key != null) temp[key] = value
            return this
        }
        override fun putLong(key: String?, value: Long): SharedPreferences.Editor {
            if (key != null) temp[key] = value
            return this
        }
        override fun putFloat(key: String?, value: Float): SharedPreferences.Editor {
            if (key != null) temp[key] = value
            return this
        }
        override fun putBoolean(key: String?, value: Boolean): SharedPreferences.Editor {
            if (key != null) temp[key] = value
            return this
        }
        override fun remove(key: String?): SharedPreferences.Editor {
            if (key != null) temp[key] = null
            return this
        }
        override fun clear(): SharedPreferences.Editor {
            clearRequested = true
            return this
        }
        override fun commit(): Boolean {
            apply()
            return true
        }
        override fun apply() {
            if (clearRequested) backing.clear()
            for ((k, v) in temp) {
                if (v == null) backing.remove(k) else backing[k] = v
            }
        }
    }
}

class OtpPreferencesWhitelistTest {

    private lateinit var fakePrefs: FakeSharedPreferences
    private lateinit var otpPrefs: OtpPreferences

    @Before
    fun setUp() {
        fakePrefs = FakeSharedPreferences()
        otpPrefs = OtpPreferences(fakePrefs)
    }

    @Test
    fun `two channels maintain completely isolated whitelist configs`() {
        val ch1Entries = listOf(
            WhitelistEntry(address = "VCB", allowOtp = true),
            WhitelistEntry(address = "+8490", allowOtp = false)
        )
        val ch2Entries = listOf(
            WhitelistEntry(address = "MOMO", allowOtp = true)
        )

        otpPrefs.setWhitelistConfig("ch-1", WhitelistMode.ALL_ADDRESSES, ch1Entries, version = 3)
        otpPrefs.setWhitelistConfig("ch-2", WhitelistMode.EXPLICIT, ch2Entries, version = 7)

        val (ch1Mode, ch1List, ch1Version) = otpPrefs.getWhitelistConfig("ch-1")
        assertEquals(WhitelistMode.ALL_ADDRESSES, ch1Mode)
        assertEquals(2, ch1List.size)
        assertEquals("VCB", ch1List[0].address)
        assertTrue(ch1List[0].allowOtp)
        assertEquals("+8490", ch1List[1].address)
        assertFalse(ch1List[1].allowOtp)
        assertEquals(3, ch1Version)

        val (ch2Mode, ch2List, ch2Version) = otpPrefs.getWhitelistConfig("ch-2")
        assertEquals(WhitelistMode.EXPLICIT, ch2Mode)
        assertEquals(1, ch2List.size)
        assertEquals("MOMO", ch2List[0].address)
        assertTrue(ch2List[0].allowOtp)
        assertEquals(7, ch2Version)
    }

    @Test
    fun `legacy global whitelist migrates to channel on first access and cleans up`() {
        val legacyJson = """[{"address":"TPBANK","allow_otp":true}]"""
        fakePrefs.edit()
            .putString("whitelist_v2_entries", legacyJson)
            .putString("whitelist_v2_mode", "EXPLICIT")
            .apply()

        assertTrue(fakePrefs.contains("whitelist_v2_entries"))

        val (mode, entries, version) = otpPrefs.getWhitelistConfig("ch-migrated")
        assertEquals(WhitelistMode.EXPLICIT, mode)
        assertEquals(1, entries.size)
        assertEquals("TPBANK", entries[0].address)
        assertTrue(entries[0].allowOtp)
        assertEquals(1, version)

        // Legacy global keys must be cleared
        assertFalse(fakePrefs.contains("whitelist_v2_entries"))
        assertFalse(fakePrefs.contains("whitelist_v2_mode"))
    }

    @Test
    fun `defensive parsing handles allowOtp camelCase and allow_otp snake_case`() {
        val mixedJson = """[
            {"address":"VCB","allowOtp":true},
            {"address":"AGRIBANK","allow_otp":true},
            {"address":"BIDV"}
        ]"""
        fakePrefs.edit()
            .putString("whitelist_ch-mixed_entries", mixedJson)
            .putString("whitelist_ch-mixed_mode", "EXPLICIT")
            .putInt("whitelist_ch-mixed_version", 5)
            .apply()

        val (mode, entries, version) = otpPrefs.getWhitelistConfig("ch-mixed")
        assertEquals(WhitelistMode.EXPLICIT, mode)
        assertEquals(3, entries.size)
        assertEquals("VCB", entries[0].address)
        assertTrue(entries[0].allowOtp)
        assertEquals("AGRIBANK", entries[1].address)
        assertTrue(entries[1].allowOtp)
        assertEquals("BIDV", entries[2].address)
        assertFalse(entries[2].allowOtp)
        assertEquals(5, version)
    }

    @Test
    fun `empty or null channelId returns deny-by-default empty config`() {
        val (modeNull, entriesNull, versionNull) = otpPrefs.getWhitelistConfig(null)
        assertEquals(WhitelistMode.EXPLICIT, modeNull)
        assertTrue(entriesNull.isEmpty())
        assertEquals(1, versionNull)

        val (modeBlank, entriesBlank, versionBlank) = otpPrefs.getWhitelistConfig("   ")
        assertEquals(WhitelistMode.EXPLICIT, modeBlank)
        assertTrue(entriesBlank.isEmpty())
        assertEquals(1, versionBlank)
    }
}
