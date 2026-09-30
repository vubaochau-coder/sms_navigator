import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';

PairingPayloadModel _samplePayload({
  String pairId = 'pair_1948b2f_9a8c1d2e',
  String secret = 'A7f9C2e5B1d8F4a6E3c7D0b9A5f2C8e1',
  int expiresAt = 1948291200000,
}) {
  return PairingPayloadModel(
    pairId: pairId,
    sharedSecretBase64: secret,
    createdAt: 1948290600000,
    expiresAt: expiresAt,
  );
}

void main() {
  group('PairingPayloadModel QR data', () {
    test('toQrData/fromQrData round-trip preserves payload', () {
      final payload = _samplePayload();

      final decoded = PairingPayloadModel.fromQrData(payload.toQrData());

      expect(decoded.pairId, payload.pairId);
      expect(decoded.sharedSecretBase64, payload.sharedSecretBase64);
      expect(decoded.expiresAt, payload.expiresAt);
    });

    test('toQrData emits versioned JSON with compact keys', () {
      final payload = _samplePayload();
      final qrData = payload.toQrData();

      expect(qrData, contains('"v":1'));
      expect(qrData, contains('"pairId":"${payload.pairId}"'));
      expect(qrData, contains('"secret":"${payload.sharedSecretBase64}"'));
      expect(qrData, contains('"exp":${payload.expiresAt}'));
      expect(qrData, isNot(contains('sharedSecretBase64')));
    });

    test('fromQrData throws FormatException on malformed JSON', () {
      expect(
        () => PairingPayloadModel.fromQrData('this is not json'),
        throwsFormatException,
      );
    });

    test('fromQrData throws FormatException on missing fields', () {
      expect(
        () => PairingPayloadModel.fromQrData('{"secret":"abc"}'),
        throwsFormatException,
      );
      expect(
        () => PairingPayloadModel.fromQrData('{"pairId":"pair_1"}'),
        throwsFormatException,
      );
    });

    test('isExpired reflects current time vs expiresAt', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(_samplePayload(expiresAt: now + 60000).isExpired, isFalse);
      expect(_samplePayload(expiresAt: now - 1000).isExpired, isTrue);
    });
  });

  group('PairingPayloadModel map serialization', () {
    test('toMap exports both secret and sharedSecretBase64 keys', () {
      final payload = _samplePayload();
      final map = payload.toMap();

      expect(map['sharedSecretBase64'], payload.sharedSecretBase64);
      expect(map['secret'], payload.sharedSecretBase64);
      expect(map['pairId'], payload.pairId);
    });

    test('fromMap accepts legacy sharedSecretBase64 key', () {
      final map = {
        'pairId': 'pair_legacy',
        'sharedSecretBase64': 'LEGACY_KEY',
        'createdAt': 100,
        'expiresAt': 200,
      };

      final payload = PairingPayloadModel.fromMap(map);

      expect(payload.sharedSecretBase64, 'LEGACY_KEY');
    });

    test('fromMap accepts compact secret key', () {
      final map = {
        'pairId': 'pair_compact',
        'secret': 'COMPACT_KEY',
        'createdAt': 100,
        'expiresAt': 200,
      };

      final payload = PairingPayloadModel.fromMap(map);

      expect(payload.sharedSecretBase64, 'COMPACT_KEY');
    });

    test('code defaults to empty string for QR payloads', () {
      expect(_samplePayload().code, '');
    });
  });
}
