import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/channel_crypto_helper.dart';
import 'package:sms_navigator/core/utils/crypto_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChannelCryptoHelper cryptoHelper;

  setUp(() {
    cryptoHelper = ChannelCryptoHelper();
  });

  group('ChannelCryptoHelper (SRD §7 Contract)', () {
    test('generateX25519IdentityKeyPair produces valid 32-byte Base64 keys', () async {
      final keyPair = await cryptoHelper.generateX25519IdentityKeyPair();
      expect(keyPair.publicKeyBase64.isNotEmpty, isTrue);
      expect(keyPair.privateKeyBase64.isNotEmpty, isTrue);
    });

    test('wrap and unwrap Key Envelope round-trips correctly with canonical AAD', () async {
      // 1. Máy A (Owner) và Máy B (Receiver)
      final ownerKeyPair = await cryptoHelper.generateX25519IdentityKeyPair();
      final receiverKeyPair = await cryptoHelper.generateX25519IdentityKeyPair();

      const channelId = 'ch_1toN_test';
      const keyEpoch = 2;
      const receiverDeviceId = 'device_receiver_b';

      // 2. Channel Key bí mật (AES-256)
      final originalChannelKey = CryptoHelper.generateSecretKeyBase64();

      // 3. Đóng gói envelope cho Máy B
      final envelope = await cryptoHelper.wrapKeyForDevice(
        channelKeyBase64: originalChannelKey,
        ownerPrivateKeyBase64: ownerKeyPair.privateKeyBase64,
        receiverPublicKeyBase64: receiverKeyPair.publicKeyBase64,
        channelId: channelId,
        keyEpoch: keyEpoch,
        receiverDeviceId: receiverDeviceId,
      );

      expect(envelope.wrappedKeyBase64.isNotEmpty, isTrue);
      expect(envelope.nonceBase64.isNotEmpty, isTrue);

      // 4. Máy B mở envelope bằng private key của mình và public key của Owner
      final unwrappedKey = await cryptoHelper.unwrapKeyEnvelope(
        wrappedKeyBase64: envelope.wrappedKeyBase64,
        nonceBase64: envelope.nonceBase64,
        myPrivateKeyBase64: receiverKeyPair.privateKeyBase64,
        ownerPublicKeyBase64: ownerKeyPair.publicKeyBase64,
        channelId: channelId,
        keyEpoch: keyEpoch,
        myDeviceId: receiverDeviceId,
      );

      expect(unwrappedKey, equals(originalChannelKey));
    });

    test('unwrap fails if AAD (e.g. wrong device_id or epoch) is mismatched', () async {
      final ownerKeyPair = await cryptoHelper.generateX25519IdentityKeyPair();
      final receiverKeyPair = await cryptoHelper.generateX25519IdentityKeyPair();

      const channelId = 'ch_1toN_test';
      const keyEpoch = 1;
      final originalChannelKey = CryptoHelper.generateSecretKeyBase64();

      final envelope = await cryptoHelper.wrapKeyForDevice(
        channelKeyBase64: originalChannelKey,
        ownerPrivateKeyBase64: ownerKeyPair.privateKeyBase64,
        receiverPublicKeyBase64: receiverKeyPair.publicKeyBase64,
        channelId: channelId,
        keyEpoch: keyEpoch,
        receiverDeviceId: 'device_b',
      );

      // Mở với device_id khác ('device_c') -> phải fail do AAD binding
      expect(
        () async => await cryptoHelper.unwrapKeyEnvelope(
          wrappedKeyBase64: envelope.wrappedKeyBase64,
          nonceBase64: envelope.nonceBase64,
          myPrivateKeyBase64: receiverKeyPair.privateKeyBase64,
          ownerPublicKeyBase64: ownerKeyPair.publicKeyBase64,
          channelId: channelId,
          keyEpoch: keyEpoch,
          myDeviceId: 'device_c', // Wrong device ID
        ),
        throwsA(isA<ChannelCryptoException>()),
      );
    });

    test('message encryption and decryption round-trips with AAD binding', () async {
      const channelId = 'ch_msg_test';
      const keyEpoch = 3;
      const plaintext = '{"sender":"Vietcombank","body":"Mã OTP của bạn là 654321"}';
      final channelKey = CryptoHelper.generateSecretKeyBase64();

      final encrypted = await cryptoHelper.encryptMessage(
        plaintext: plaintext,
        channelKeyBase64: channelKey,
        channelId: channelId,
        keyEpoch: keyEpoch,
        sequenceHint: 0,
      );

      expect(encrypted.ciphertextBase64.isNotEmpty, isTrue);
      expect(encrypted.nonceBase64.isNotEmpty, isTrue);

      final decrypted = await cryptoHelper.decryptMessage(
        ciphertextBase64: encrypted.ciphertextBase64,
        nonceBase64: encrypted.nonceBase64,
        channelKeyBase64: channelKey,
        channelId: channelId,
        keyEpoch: keyEpoch,
        sequenceHint: 0,
      );

      expect(decrypted, equals(plaintext));
    });

    test('decrypting message with wrong epoch throws exception', () async {
      const channelId = 'ch_msg_test';
      const keyEpoch = 1;
      const plaintext = 'Secret OTP message';
      final channelKey = CryptoHelper.generateSecretKeyBase64();

      final encrypted = await cryptoHelper.encryptMessage(
        plaintext: plaintext,
        channelKeyBase64: channelKey,
        channelId: channelId,
        keyEpoch: keyEpoch,
      );

      // Decrypt with different epoch (epoch = 2) -> AAD mismatch -> throws
      expect(
        () async => await cryptoHelper.decryptMessage(
          ciphertextBase64: encrypted.ciphertextBase64,
          nonceBase64: encrypted.nonceBase64,
          channelKeyBase64: channelKey,
          channelId: channelId,
          keyEpoch: 2, // Wrong epoch
        ),
        throwsA(isA<ChannelCryptoException>()),
      );
    });
  });
}
