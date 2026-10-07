package com.example.sms_navigator.crypto

import android.util.Base64
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object ChannelCryptoNative {

    private const val ALGORITHM = "AES/GCM/NoPadding"
    private const val GCM_TAG_LENGTH_BIT = 128
    private const val GCM_IV_LENGTH_BYTE = 12
    private const val MSG_DOMAIN = "sms-navigator-msg-v1"

    data class EncryptedMessageResult(
        val ciphertextBase64: String,
        val nonceBase64: String
    )

    /**
     * Khớp chính xác với CanonicalEncoding.messageAad trong Dart (SRD 7.1, KL10):
     * "sms-navigator-msg-v1" || u32le(len(ch)) || ch || u64le(epoch) || u64le(seqHint=0)
     */
    fun buildMessageAad(channelId: String, keyEpoch: Long, sequenceHint: Long = 0L): ByteArray {
        val bos = ByteArrayOutputStream()
        bos.write(MSG_DOMAIN.toByteArray(Charsets.UTF_8))

        // _lenPrefixedString(channelId) = u32le(len) || utf8(channelId)
        val chBytes = channelId.toByteArray(Charsets.UTF_8)
        val lenBuf = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        lenBuf.putInt(chBytes.size)
        bos.write(lenBuf.array())
        bos.write(chBytes)

        // u64le(keyEpoch)
        val epochBuf = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN)
        epochBuf.putLong(keyEpoch)
        bos.write(epochBuf.array())

        // u64le(sequenceHint)
        val seqBuf = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN)
        seqBuf.putLong(sequenceHint)
        bos.write(seqBuf.array())

        return bos.toByteArray()
    }

    private fun base64Decode(str: String): ByteArray {
        return try {
            java.util.Base64.getDecoder().decode(str)
        } catch (_: Throwable) {
            android.util.Base64.decode(str, android.util.Base64.NO_WRAP)
        }
    }

    private fun base64Encode(bytes: ByteArray): String {
        return try {
            java.util.Base64.getEncoder().encodeToString(bytes)
        } catch (_: Throwable) {
            android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
        }
    }

    /**
     * Mã hóa tin nhắn bằng AES-256-GCM với AAD theo chuẩn kiến trúc Channel E2EE V2.
     * Output Base64(ciphertext || tag-16B) và Base64(nonce-12B).
     */
    fun encryptMessage(
        plaintext: String,
        channelKeyBase64: String,
        channelId: String,
        keyEpoch: Long,
        sequenceHint: Long = 0L
    ): EncryptedMessageResult {
        val keyBytes = base64Decode(channelKeyBase64)
        require(keyBytes.size == 32) { "Channel Key must be exactly 32 bytes (AES-256)" }

        val iv = ByteArray(GCM_IV_LENGTH_BYTE)
        SecureRandom().nextBytes(iv)

        val aad = buildMessageAad(channelId, keyEpoch, sequenceHint)

        val cipher = Cipher.getInstance(ALGORITHM)
        val secretKey = SecretKeySpec(keyBytes, "AES")
        val spec = GCMParameterSpec(GCM_TAG_LENGTH_BIT, iv)

        cipher.init(Cipher.ENCRYPT_MODE, secretKey, spec)
        cipher.updateAAD(aad)

        val cipherTextWithTag = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))

        return EncryptedMessageResult(
            ciphertextBase64 = base64Encode(cipherTextWithTag),
            nonceBase64 = base64Encode(iv)
        )
    }
}
