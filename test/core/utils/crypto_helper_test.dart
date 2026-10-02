import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/crypto_helper.dart';

void main() {
  group('encryptAesGcm256 / decryptAesGcm256 round-trip', () {
    test('encrypts then decrypts ASCII plaintext', () async {
      final secretKeyBase64 = CryptoHelper.generateSecretKeyBase64();
      const plaintext = 'OTP 482913 from Viettel';

      final encrypted = await CryptoHelper.encryptAesGcm256(
        plaintext: plaintext,
        secretKeyBase64: secretKeyBase64,
      );

      expect(encrypted['ciphertext'], isNotNull);
      expect(encrypted['iv'], isNotNull);

      // IV phải là 12 byte — khớp IV_LENGTH_BYTE của Android native.
      expect(base64Decode(encrypted['iv']!).length, 12);

      final decrypted = await CryptoHelper.decryptAesGcm256(
        ciphertextWithTagBase64: encrypted['ciphertext']!,
        ivBase64: encrypted['iv']!,
        secretKeyBase64: secretKeyBase64,
      );

      expect(decrypted, plaintext);
    });

    test('encrypts then decrypts unicode plaintext', () async {
      final secretKeyBase64 = CryptoHelper.generateSecretKeyBase64();
      const plaintext = 'Xin chào! Mã OTP: 881 234 —🔐 end';

      final encrypted = await CryptoHelper.encryptAesGcm256(
        plaintext: plaintext,
        secretKeyBase64: secretKeyBase64,
      );

      final decrypted = await CryptoHelper.decryptAesGcm256(
        ciphertextWithTagBase64: encrypted['ciphertext']!,
        ivBase64: encrypted['iv']!,
        secretKeyBase64: secretKeyBase64,
      );

      expect(decrypted, plaintext);
    });

    test('produces unique IV per encryption', () async {
      final secretKeyBase64 = CryptoHelper.generateSecretKeyBase64();

      final first = await CryptoHelper.encryptAesGcm256(
        plaintext: 'same input',
        secretKeyBase64: secretKeyBase64,
      );
      final second = await CryptoHelper.encryptAesGcm256(
        plaintext: 'same input',
        secretKeyBase64: secretKeyBase64,
      );

      expect(first['iv'], isNot(second['iv']));
      expect(first['ciphertext'], isNot(second['ciphertext']));
    });

    test('ciphertext embeds a 16-byte GCM tag', () async {
      final secretKeyBase64 = CryptoHelper.generateSecretKeyBase64();
      const plaintext = '123456';

      final encrypted = await CryptoHelper.encryptAesGcm256(
        plaintext: plaintext,
        secretKeyBase64: secretKeyBase64,
      );

      final fullBytes = base64Decode(encrypted['ciphertext']!);
      // plaintext (6 bytes UTF-8) + 16-byte tag.
      expect(fullBytes.length, utf8.encode(plaintext).length + 16);
    });
  });

  group('decryptAesGcm256 known-answer vector', () {
    // Vector sinh chuẩn AES-256-GCM (nonce 12 byte, tag 128 bit nối cuối
    // ciphertext) — cùng định dạng Base64(cipherText || tag) mà
    // OtpCrypto.kt trên Android native xuất ra.
    const katKeyBase64 = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=';
    const katIvBase64 = 'AAECAwQFBgcICQoL';
    const katCiphertextBase64 =
        'FE+FNouEtHLqIOPkw9NCIteGqgDISWZNC13f3XQHINFp0w6TL9G66fo/UWt1Ggp4eOQjnQ==';
    const katPlaintext = 'SMS-Navigator::OTP-482913::Xin chào';

    test(
      'decrypts a fixed AES-256-GCM vector (Android native compatible)',
      () async {
        final decrypted = await CryptoHelper.decryptAesGcm256(
          ciphertextWithTagBase64: katCiphertextBase64,
          ivBase64: katIvBase64,
          secretKeyBase64: katKeyBase64,
        );

        expect(decrypted, katPlaintext);
      },
    );

    test('re-encrypting the KAT plaintext decrypts back identically', () async {
      final encrypted = await CryptoHelper.encryptAesGcm256(
        plaintext: katPlaintext,
        secretKeyBase64: katKeyBase64,
      );

      final decrypted = await CryptoHelper.decryptAesGcm256(
        ciphertextWithTagBase64: encrypted['ciphertext']!,
        ivBase64: encrypted['iv']!,
        secretKeyBase64: katKeyBase64,
      );

      expect(decrypted, katPlaintext);
    });
  });

  group('decryptAesGcm256 error handling', () {
    test(
      'throws FormatException when ciphertext is shorter than the GCM tag',
      () async {
        final secretKeyBase64 = CryptoHelper.generateSecretKeyBase64();
        final shortCiphertext = base64Encode([1, 2, 3]);

        expect(
          () => CryptoHelper.decryptAesGcm256(
            ciphertextWithTagBase64: shortCiphertext,
            ivBase64: base64Encode(List<int>.filled(12, 0)),
            secretKeyBase64: secretKeyBase64,
          ),
          throwsFormatException,
        );
      },
    );

    test('fails authentication when ciphertext is tampered', () async {
      final secretKeyBase64 = CryptoHelper.generateSecretKeyBase64();

      final encrypted = await CryptoHelper.encryptAesGcm256(
        plaintext: 'tamper me',
        secretKeyBase64: secretKeyBase64,
      );

      final bytes = base64Decode(encrypted['ciphertext']!);
      bytes[0] = bytes[0] ^ 0xFF;
      final tampered = base64Encode(bytes);

      expect(
        () => CryptoHelper.decryptAesGcm256(
          ciphertextWithTagBase64: tampered,
          ivBase64: encrypted['iv']!,
          secretKeyBase64: secretKeyBase64,
        ),
        throwsA(anything),
      );
    });

    test('fails authentication when the key is wrong', () async {
      final secretKeyBase64 = CryptoHelper.generateSecretKeyBase64();
      final otherKeyBase64 = CryptoHelper.generateSecretKeyBase64();

      final encrypted = await CryptoHelper.encryptAesGcm256(
        plaintext: 'secret payload',
        secretKeyBase64: secretKeyBase64,
      );

      expect(
        () => CryptoHelper.decryptAesGcm256(
          ciphertextWithTagBase64: encrypted['ciphertext']!,
          ivBase64: encrypted['iv']!,
          secretKeyBase64: otherKeyBase64,
        ),
        throwsA(anything),
      );
    });
  });

  group('X25519 keypair generation', () {
    test('generates a 32-byte seed-based private key and 32-byte public key', () async {
      final keys = await CryptoHelper.generateX25519KeyPairBase64();

      expect(base64Decode(keys.privateKeyBase64).length, 32);
      expect(base64Decode(keys.publicKeyBase64).length, 32);
      expect(keys.publicKeyBase64, isNot(keys.privateKeyBase64));
    });

    test('generates unique keypairs across calls', () async {
      final first = await CryptoHelper.generateX25519KeyPairBase64();
      final second = await CryptoHelper.generateX25519KeyPairBase64();

      expect(first.privateKeyBase64, isNot(second.privateKeyBase64));
      expect(first.publicKeyBase64, isNot(second.publicKeyBase64));
    });
  });

  group('ECDH derivePairingSecretBase64 (pairing v3)', () {
    test('both parties derive the identical 32-byte shared secret', () async {
      final sender = await CryptoHelper.generateX25519KeyPairBase64();
      final receiver = await CryptoHelper.generateX25519KeyPairBase64();
      const pairId = 'pair_ecdh_roundtrip';

      final senderSecret = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: sender.privateKeyBase64,
        remotePublicKeyBase64: receiver.publicKeyBase64,
        salt: pairId,
      );
      final receiverSecret = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: receiver.privateKeyBase64,
        remotePublicKeyBase64: sender.publicKeyBase64,
        salt: pairId,
      );

      expect(senderSecret, receiverSecret);
      // Khớp AES-256 (32 byte) của OtpCrypto.kt
      expect(base64Decode(senderSecret).length, 32);
    });

    test('derives deterministic output for the same inputs', () async {
      final sender = await CryptoHelper.generateX25519KeyPairBase64();
      final receiver = await CryptoHelper.generateX25519KeyPairBase64();

      final first = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: sender.privateKeyBase64,
        remotePublicKeyBase64: receiver.publicKeyBase64,
        salt: 'pair_same_salt',
      );
      final second = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: sender.privateKeyBase64,
        remotePublicKeyBase64: receiver.publicKeyBase64,
        salt: 'pair_same_salt',
      );

      expect(first, second);
    });

    test('different pairId salts yield different secrets', () async {
      final sender = await CryptoHelper.generateX25519KeyPairBase64();
      final receiver = await CryptoHelper.generateX25519KeyPairBase64();

      final first = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: sender.privateKeyBase64,
        remotePublicKeyBase64: receiver.publicKeyBase64,
        salt: 'pair_first',
      );
      final second = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: sender.privateKeyBase64,
        remotePublicKeyBase64: receiver.publicKeyBase64,
        salt: 'pair_second',
      );

      expect(first, isNot(second));
    });

    test('derived secret works as an AES-256-GCM key end-to-end', () async {
      final sender = await CryptoHelper.generateX25519KeyPairBase64();
      final receiver = await CryptoHelper.generateX25519KeyPairBase64();
      const pairId = 'pair_aes_usage';

      final secret = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: sender.privateKeyBase64,
        remotePublicKeyBase64: receiver.publicKeyBase64,
        salt: pairId,
      );

      const plaintext = 'OTP 552210';
      final encrypted = await CryptoHelper.encryptAesGcm256(
        plaintext: plaintext,
        secretKeyBase64: secret,
      );
      final decrypted = await CryptoHelper.decryptAesGcm256(
        ciphertextWithTagBase64: encrypted['ciphertext']!,
        ivBase64: encrypted['iv']!,
        secretKeyBase64: secret,
      );

      expect(decrypted, plaintext);
    });
  });
}
