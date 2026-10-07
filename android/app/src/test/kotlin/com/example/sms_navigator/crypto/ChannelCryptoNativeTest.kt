package com.example.sms_navigator.crypto

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

class ChannelCryptoNativeTest {

    @Test
    fun testBuildMessageAadCanonicalStructure() {
        val channelId = "ch-12345"
        val epoch = 3L

        val aad = ChannelCryptoNative.buildMessageAad(channelId, epoch)

        val prefixBytes = "sms-navigator-msg-v1".toByteArray(Charsets.UTF_8)
        val channelIdBytes = channelId.toByteArray(Charsets.UTF_8)

        val expectedLength = prefixBytes.size + 4 + channelIdBytes.size + 8 + 8
        assertEquals(expectedLength, aad.size)

        val buf = ByteBuffer.wrap(aad).order(ByteOrder.LITTLE_ENDIAN)

        // 1. Prefix
        val actualPrefix = ByteArray(prefixBytes.size)
        buf.get(actualPrefix)
        assertArrayEquals(prefixBytes, actualPrefix)

        // 2. ChannelId length (u32le)
        val actualLen = buf.int
        assertEquals(channelIdBytes.size, actualLen)

        // 3. ChannelId string
        val actualChannelBytes = ByteArray(channelIdBytes.size)
        buf.get(actualChannelBytes)
        assertArrayEquals(channelIdBytes, actualChannelBytes)

        // 4. Epoch (u64le)
        val actualEpoch = buf.long
        assertEquals(epoch, actualEpoch)

        // 5. Counter (u64le = 0)
        val actualCounter = buf.long
        assertEquals(0L, actualCounter)
    }

    @Test
    fun testEncryptMessageRoundTrip() {
        // 32-byte AES key
        val rawKey = ByteArray(32) { (it + 1).toByte() }
        val keyBase64 = Base64.getEncoder().encodeToString(rawKey)

        val channelId = "demo-channel"
        val epoch = 1L
        val plaintext = "Mã OTP của bạn là 654321 tại VCB."

        val encrypted = ChannelCryptoNative.encryptMessage(
            plaintext = plaintext,
            channelKeyBase64 = keyBase64,
            channelId = channelId,
            keyEpoch = epoch
        )

        assertNotNull(encrypted.ciphertextBase64)
        assertNotNull(encrypted.nonceBase64)

        val ciphertextWithTag = Base64.getDecoder().decode(encrypted.ciphertextBase64)
        val nonce = Base64.getDecoder().decode(encrypted.nonceBase64)

        assertEquals(12, nonce.size)
        // Tag is 16 bytes, ciphertext size must be plaintext size + 16
        val plainBytes = plaintext.toByteArray(Charsets.UTF_8)
        assertEquals(plainBytes.size + 16, ciphertextWithTag.size)

        // Decrypt using standard AES-GCM Cipher to ensure correctness
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val keySpec = SecretKeySpec(rawKey, "AES")
        val gcmSpec = GCMParameterSpec(128, nonce)
        cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec)
        cipher.updateAAD(ChannelCryptoNative.buildMessageAad(channelId, epoch))

        val decryptedBytes = cipher.doFinal(ciphertextWithTag)
        val decryptedText = String(decryptedBytes, Charsets.UTF_8)

        assertEquals(plaintext, decryptedText)
    }
}
