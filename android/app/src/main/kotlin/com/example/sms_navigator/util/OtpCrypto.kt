package com.example.sms_navigator.util

import android.util.Base64
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object OtpCrypto {

    private const val ALGORITHM = "AES/GCM/NoPadding"
    private const val TAG_LENGTH_BIT = 128
    private const val IV_LENGTH_BYTE = 12

    data class EncryptedResult(
        val ciphertextBase64: String,
        val ivBase64: String
    )

    /**
     * Encrypts plaintext using AES-256-GCM with a random 12-byte IV.
     */
    fun encrypt(plaintext: String, keyBytes: ByteArray): EncryptedResult {
        // Ensure key is 32 bytes (256 bits)
        val normalizedKey = if (keyBytes.size == 32) {
            keyBytes
        } else {
            java.security.MessageDigest.getInstance("SHA-256").digest(keyBytes)
        }

        val secretKey = SecretKeySpec(normalizedKey, "AES")
        val iv = ByteArray(IV_LENGTH_BYTE)
        SecureRandom().nextBytes(iv)

        val cipher = Cipher.getInstance(ALGORITHM)
        val spec = GCMParameterSpec(TAG_LENGTH_BIT, iv)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, spec)

        val encryptedBytes = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))

        return EncryptedResult(
            ciphertextBase64 = encodeBase64(encryptedBytes),
            ivBase64 = encodeBase64(iv)
        )
    }

    /**
     * Decrypts ciphertextBase64 using AES-256-GCM.
     */
    fun decrypt(ciphertextBase64: String, ivBase64: String, keyBytes: ByteArray): String {
        val normalizedKey = if (keyBytes.size == 32) {
            keyBytes
        } else {
            java.security.MessageDigest.getInstance("SHA-256").digest(keyBytes)
        }

        val secretKey = SecretKeySpec(normalizedKey, "AES")
        val iv = decodeBase64(ivBase64)
        val ciphertext = decodeBase64(ciphertextBase64)

        val cipher = Cipher.getInstance(ALGORITHM)
        val spec = GCMParameterSpec(TAG_LENGTH_BIT, iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)

        val decryptedBytes = cipher.doFinal(ciphertext)
        return String(decryptedBytes, Charsets.UTF_8)
    }

    private fun encodeBase64(bytes: ByteArray): String {
        return try {
            java.util.Base64.getEncoder().encodeToString(bytes)
        } catch (e: Throwable) {
            android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
        }
    }

    private fun decodeBase64(str: String): ByteArray {
        return try {
            java.util.Base64.getDecoder().decode(str)
        } catch (e: Throwable) {
            android.util.Base64.decode(str, android.util.Base64.NO_WRAP)
        }
    }
}
