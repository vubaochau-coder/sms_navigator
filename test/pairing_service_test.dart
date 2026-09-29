import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';
import 'package:sms_navigator/features/pairing/data/services/pairing_service.dart';
import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';

class _FakeNativeRelayService implements NativeRelayService {
  Map<String, dynamic>? lastConfig;

  @override
  Future<Map<String, dynamic>> getRelayConfig() async => lastConfig ?? {};

  @override
  Future<bool> setRelayConfig({
    bool? isRelayEnabled,
    String? pairId,
    String? sharedSecretBase64,
    String? relayUrl,
    String? deviceToken,
    String? deviceId,
  }) async {
    lastConfig = {
      'isRelayEnabled': isRelayEnabled,
      'pairId': pairId,
      'sharedSecretBase64': sharedSecretBase64,
      'relayUrl': relayUrl,
      'deviceToken': deviceToken,
      'deviceId': deviceId,
    };
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async => [];

  @override
  Future<bool> clearPairing() async {
    lastConfig = null;
    return true;
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;

  @override
  Future<bool> requestIgnoreBatteryOptimization() async => true;

  @override
  void setOnOtpDetectedListener(Function(String sender, String otp) listener) {}
}

PairingServiceImpl _buildService() {
  return PairingServiceImpl(nativeService: _FakeNativeRelayService());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('generateSenderPairing', () {
    test('generates a 256-bit random secret with 10 minute TTL', () async {
      final service = _buildService();

      final payload = await service.generateSenderPairing();

      expect(payload.code, '');
      expect(payload.pairId, startsWith('pair_'));
      expect(
        payload.expiresAt - payload.createdAt,
        10 * 60 * 1000,
      );
      final secretBytes = base64Decode(payload.sharedSecretBase64);
      expect(secretBytes.length, 32);
    });

    test('generates unique secrets per session', () async {
      final service = _buildService();

      final first = await service.generateSenderPairing();
      final second = await service.generateSenderPairing();

      expect(first.sharedSecretBase64, isNot(second.sharedSecretBase64));
    });
  });

  group('confirmReceiverPairingFromQr', () {
    test('stores pairId and shared secret for a valid QR payload',
        () async {
      final service = _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_valid_1234',
        sharedSecretBase64: 'VALID_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      final ok = await service.confirmReceiverPairingFromQr(payload.toQrData());

      expect(ok, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('receiver_pair_id'), 'pair_valid_1234');
      expect(prefs.getString('receiver_shared_secret'), 'VALID_SECRET');
    });

    test('rejects an expired QR payload', () async {
      final service = _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_expired',
        sharedSecretBase64: 'EXPIRED_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch - 120000,
        expiresAt: DateTime.now().millisecondsSinceEpoch - 60000,
      );

      final ok = await service.confirmReceiverPairingFromQr(payload.toQrData());

      expect(ok, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('receiver_pair_id'), isNull);
      expect(prefs.getString('receiver_shared_secret'), isNull);
    });

    test('rejects malformed QR data', () async {
      final service = _buildService();

      expect(await service.confirmReceiverPairingFromQr('garbage'), isFalse);
      expect(
        await service.confirmReceiverPairingFromQr('{"exp":123}'),
        isFalse,
      );
    });
  });

  group('confirmReceiverPairing (legacy alias)', () {
    test('rejects the removed 6-digit OTP code mechanism', () async {
      final service = _buildService();

      final ok = await service.confirmReceiverPairing('123456');

      expect(ok, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('receiver_pair_id'), isNull);
    });

    test('still accepts a QR payload string', () async {
      final service = _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_via_alias',
        sharedSecretBase64: 'ALIAS_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      final ok = await service.confirmReceiverPairing(payload.toQrData());

      expect(ok, isTrue);
    });
  });

  group('getReceiverPairing / clearReceiverPairing', () {
    test('returns null before pairing and payload after pairing', () async {
      final service = _buildService();

      expect(await service.getReceiverPairing(), isNull);

      final payload = PairingPayloadModel(
        pairId: 'pair_status_check',
        sharedSecretBase64: 'STATUS_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );
      await service.confirmReceiverPairingFromQr(payload.toQrData());

      final stored = await service.getReceiverPairing();
      expect(stored, isNotNull);
      expect(stored!.pairId, 'pair_status_check');
      expect(stored.sharedSecretBase64, 'STATUS_SECRET');
    });

    test('clearReceiverPairing removes stored pairing data', () async {
      final service = _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_to_clear',
        sharedSecretBase64: 'CLEAR_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );
      await service.confirmReceiverPairingFromQr(payload.toQrData());

      final cleared = await service.clearReceiverPairing();

      expect(cleared, isTrue);
      expect(await service.getReceiverPairing(), isNull);
    });
  });
}
