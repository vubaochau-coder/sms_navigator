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
}
