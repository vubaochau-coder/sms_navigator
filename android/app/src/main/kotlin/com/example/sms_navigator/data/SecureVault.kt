package com.example.sms_navigator.data

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Vault mã hóa giá trị nhạy cảm at-rest (roadmap GĐ4.1).
 *
 * Key AES-256 nằm trong Android Keystore (không thể đọc/trích xuất kể cả
 * với thiết bị root ở đa số trường hợp), cipher AES-256-GCM, định dạng blob
 * lưu: Base64(iv || ciphertext || tag) — cùng định dạng với OtpCrypto.
 */
object SecureVault {

    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "otp_relay_master_key"
    private const val GCM_IV_LENGTH_BYTES = 12
    private const val GCM_TAG_LENGTH_BITS = 128

    /** Mã hóa plaintext, trả về blob Base64(iv || ciphertext). */
    fun encryptToBase64(plaintext: String): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        val iv = cipher.iv
        val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        val blob = iv + ciphertext
        return Base64.encodeToString(blob, Base64.NO_WRAP)
    }

    /** Giải mã blob Base64(iv || ciphertext), trả về plaintext. */
    fun decryptFromBase64(blobBase64: String): String {
        val blob = Base64.decode(blobBase64, Base64.NO_WRAP)
        require(blob.size > GCM_IV_LENGTH_BYTES) { "SecureVault blob too short" }
        val iv = blob.copyOfRange(0, GCM_IV_LENGTH_BYTES)
        val ciphertext = blob.copyOfRange(GCM_IV_LENGTH_BYTES, blob.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv))
        return String(cipher.doFinal(ciphertext), Charsets.UTF_8)
    }

    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let {
            return it.secretKey
        }
        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }
}
