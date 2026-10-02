import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';

const _sampleSenderPubkey = 'A7f9C2e5B1d8F4a6E3c7D0b9A5f2C8e1Q0x9Zw==';
const _sampleSenderPrivkey = 'pR2vT7kM3nJ8hG5fD1sA9qW4eR6tY0uI2oP3lK8jZxM=';

PairingPayloadModel _samplePayload({
  String pairId = 'pair_1948b2f_9a8c1d2e',
  String pairingKey = 'a9V_x8Qe2mZ1wKd5Tn7cRg',
  String senderPubkey = _sampleSenderPubkey,
  int expiresAt = 1948291200000,
}) {
  return PairingPayloadModel(
    pairId: pairId,
    pairingKey: pairingKey,
    senderPubkey: senderPubkey,
    senderPrivateKeyBase64: _sampleSenderPrivkey,
    createdAt: 1948290600000,
    expiresAt: expiresAt,
  );
}

void main() {
  group('PairingPayloadModel QR data (protocol v3 - ECDH)', () {
    test('toQrData/fromQrData round-trip preserves payload', () {
      final payload = _samplePayload();

      final decoded = PairingPayloadModel.fromQrData(payload.toQrData());

      expect(decoded.pairingKey, payload.pairingKey);
      expect(decoded.senderPubkey, payload.senderPubkey);
      expect(decoded.expiresAt, payload.expiresAt);
      // pairId do server phát hành - không nằm trong QR
      expect(decoded.pairId, isEmpty);
      // Shared secret KHÔNG BAO GIỜ nằm trong QR (ECDH)
      expect(decoded.sharedSecretBase64, isEmpty);
    });

    test('toQrData emits versioned JSON v3 with compact keys and NO secret', () {
      final payload = _samplePayload(
        senderPubkey: _sampleSenderPubkey,
      );
      final qrData = payload.toQrData();

      expect(qrData, contains('"v":3'));
      expect(qrData, contains('"k":"${payload.pairingKey}"'));
      expect(qrData, contains('"a":"$_sampleSenderPubkey"'));
      expect(qrData, contains('"e":${payload.expiresAt}'));
      // Không còn secret, không còn pairId trong QR
      expect(qrData, isNot(contains('sharedSecretBase64')));
      expect(qrData, isNot(contains('"s"')));
      expect(qrData, isNot(contains('"pairId"')));
      // Private key không bao giờ xuất hiện trong QR
      expect(qrData, isNot(contains(_sampleSenderPrivkey)));
    });

    test('fromQrData throws FormatException on malformed JSON', () {
      expect(
        () => PairingPayloadModel.fromQrData('this is not json'),
        throwsFormatException,
      );
    });

    test('fromQrData rejects retired v1 and v2 payload formats', () {
      const v1 =
          '{"v":1,"pairId":"pair_legacy","secret":"abc","exp":9999999999999}';
      const v2 = '{"v":2,"k":"a9V_x8Qe2mZ1wKd5Tn7cRg","s":"abc","e":9999999999999}';
      expect(() => PairingPayloadModel.fromQrData(v1), throwsFormatException);
      expect(() => PairingPayloadModel.fromQrData(v2), throwsFormatException);
    });

    test('fromQrData throws FormatException on missing fields', () {
      expect(
        () => PairingPayloadModel.fromQrData('{"v":3,"a":"pub","e":1}'),
        throwsFormatException,
      );
      expect(
        () => PairingPayloadModel.fromQrData('{"v":3,"k":"key","e":1}'),
        throwsFormatException,
      );
      expect(
        () => PairingPayloadModel.fromQrData('{"v":3,"k":"","a":"pub","e":1}'),
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
    test('accepts a v3 pairing payload', () {
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

    test('rejects legacy v1/v2 payloads and v3 with missing fields', () {
      expect(
        PairingPayloadModel.looksLikePairingQr(
          '{"v":1,"pairId":"pair_legacy","secret":"abc","exp":1}',
        ),
        isFalse,
      );
      expect(
        PairingPayloadModel.looksLikePairingQr(
          '{"v":2,"k":"key","s":"secret","e":1}',
        ),
        isFalse,
      );
      expect(
        PairingPayloadModel.looksLikePairingQr('{"v":3,"k":"key","e":1}'),
        isFalse,
      );
      expect(
        PairingPayloadModel.looksLikePairingQr('{"v":3,"a":"pub","e":1}'),
        isFalse,
      );
    });
  });

  group('PairingPayloadModel map serialization', () {
    test('toMap exports secret and pairingKey', () {
      final payload = _samplePayload();
      final map = payload.toMap();

      expect(map['senderPubkey'], _sampleSenderPubkey);
      expect(map['pairingKey'], payload.pairingKey);
      expect(map['pairId'], payload.pairId);
    });

    test('fromMap round-trips pairingKey and secret', () {
      final map = {
        'pairId': 'pair_from_map',
        'pairingKey': 'map_pairing_key_value',
        'senderPubkey': _sampleSenderPubkey,
        'sharedSecretBase64': 'MAP_KEY',
        'createdAt': 100,
        'expiresAt': 200,
      };

      final payload = PairingPayloadModel.fromMap(map);

      expect(payload.pairingKey, 'map_pairing_key_value');
      expect(payload.senderPubkey, _sampleSenderPubkey);
      expect(payload.sharedSecretBase64, 'MAP_KEY');
      expect(payload.pairId, 'pair_from_map');
    });

    test('decoded QR payload json is valid utf8 base64 payload', () {
      final decoded =
          jsonDecode(_samplePayload().toQrData()) as Map<String, dynamic>;
      expect(decoded['v'], 3);
      expect(decoded.keys.toSet(), containsAll(['k', 'a', 'e']));
      expect(decoded.keys.length, 4);
    });
  });
}
