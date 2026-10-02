import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';

PairingPayloadModel _samplePayload({
  String pairId = 'pair_1948b2f_9a8c1d2e',
  String pairingKey = 'a9V_x8Qe2mZ1wKd5Tn7cRg',
  String secret = 'A7f9C2e5B1d8F4a6E3c7D0b9A5f2C8e1',
  int expiresAt = 1948291200000,
}) {
  return PairingPayloadModel(
    pairId: pairId,
    pairingKey: pairingKey,
    sharedSecretBase64: secret,
    createdAt: 1948290600000,
    expiresAt: expiresAt,
  );
}

void main() {
  group('PairingPayloadModel QR data (protocol v2)', () {
    test('toQrData/fromQrData round-trip preserves payload', () {
      final payload = _samplePayload();

      final decoded = PairingPayloadModel.fromQrData(payload.toQrData());

      expect(decoded.pairingKey, payload.pairingKey);
      expect(decoded.sharedSecretBase64, payload.sharedSecretBase64);
      expect(decoded.expiresAt, payload.expiresAt);
      // pairId do server phát hành - không nằm trong QR
      expect(decoded.pairId, isEmpty);
    });

    test('toQrData emits versioned JSON v2 with compact keys', () {
      final payload = _samplePayload();
      final qrData = payload.toQrData();

      expect(qrData, contains('"v":2'));
      expect(qrData, contains('"k":"${payload.pairingKey}"'));
      expect(qrData, contains('"s":"${payload.sharedSecretBase64}"'));
      expect(qrData, contains('"e":${payload.expiresAt}'));
      // Secret field KHÔNG dùng key đầy đủ "sharedSecretBase64" trong QR
      expect(qrData, isNot(contains('sharedSecretBase64')));
      expect(qrData, isNot(contains('"pairId"')));
    });

    test('fromQrData throws FormatException on malformed JSON', () {
      expect(
        () => PairingPayloadModel.fromQrData('this is not json'),
        throwsFormatException,
      );
    });

    test('fromQrData rejects the retired v1 payload format', () {
      const legacy = '{"v":1,"pairId":"pair_legacy","secret":"abc","exp":9999999999999}';
      expect(
        () => PairingPayloadModel.fromQrData(legacy),
        throwsFormatException,
      );
    });

    test('fromQrData throws FormatException on missing fields', () {
      expect(
        () => PairingPayloadModel.fromQrData('{"v":2,"s":"abc","e":1}'),
        throwsFormatException,
      );
      expect(
        () => PairingPayloadModel.fromQrData('{"v":2,"k":"key","e":1}'),
        throwsFormatException,
      );
      expect(
        () => PairingPayloadModel.fromQrData('{"v":2,"k":"","s":"abc","e":1}'),
        throwsFormatException,
      );
    });

    test('isExpired reflects current time vs expiresAt', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(_samplePayload(expiresAt: now + 60000).isExpired, isFalse);
      expect(_samplePayload(expiresAt: now - 1000).isExpired, isTrue);
    });
  });

  group('PairingPayloadModel.looksLikePairingQr (scanner routing)', () {
    test('accepts a v2 pairing payload', () {
      expect(
        PairingPayloadModel.looksLikePairingQr(_samplePayload().toQrData()),
        isTrue,
      );
    });

    test('rejects malformed JSON and foreign payloads', () {
      expect(PairingPayloadModel.looksLikePairingQr('not json'), isFalse);
      expect(PairingPayloadModel.looksLikePairingQr('["array"]'), isFalse);
      expect(
        PairingPayloadModel.looksLikePairingQr(
          'https://example.com/qr/v1/sometoken',
        ),
        isFalse,
      );
    });

    test('rejects legacy v1 payloads and v2 with missing fields', () {
      expect(
        PairingPayloadModel.looksLikePairingQr(
          '{"v":1,"pairId":"pair_legacy","secret":"abc","exp":1}',
        ),
        isFalse,
      );
      expect(
        PairingPayloadModel.looksLikePairingQr('{"v":2,"k":"key"}'),
        isFalse,
      );
      expect(
        PairingPayloadModel.looksLikePairingQr('{"v":2,"s":"secret"}'),
        isFalse,
      );
    });
  });

  group('PairingPayloadModel map serialization', () {
    test('toMap exports secret and pairingKey', () {
      final payload = _samplePayload();
      final map = payload.toMap();

      expect(map['sharedSecretBase64'], payload.sharedSecretBase64);
      expect(map['pairingKey'], payload.pairingKey);
      expect(map['pairId'], payload.pairId);
    });

    test('fromMap round-trips pairingKey and secret', () {
      final map = {
        'pairId': 'pair_from_map',
        'pairingKey': 'map_pairing_key_value',
        'sharedSecretBase64': 'MAP_KEY',
        'createdAt': 100,
        'expiresAt': 200,
      };

      final payload = PairingPayloadModel.fromMap(map);

      expect(payload.pairingKey, 'map_pairing_key_value');
      expect(payload.sharedSecretBase64, 'MAP_KEY');
      expect(payload.pairId, 'pair_from_map');
    });
  });
}
