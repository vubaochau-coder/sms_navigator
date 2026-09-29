import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/crypto_helper.dart';
import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';
import '../models/pairing_payload_model.dart';

abstract class PairingService {
  Future<PairingPayloadModel> generateSenderPairing();
  Future<bool> confirmSenderPairing(PairingPayloadModel payload);
  Future<bool> confirmReceiverPairing(String code);
  Future<PairingPayloadModel?> getReceiverPairing();
  Future<bool> clearReceiverPairing();
}

class PairingServiceImpl implements PairingService {
  final NativeRelayService nativeService;

  PairingServiceImpl({required this.nativeService});

  static const String _keyReceiverPairId = 'receiver_pair_id';
  static const String _keyReceiverSharedSecret = 'receiver_shared_secret';
  static const String _keyReceiverPairCode = 'receiver_pair_code';
  static const String _salt = 'sms_navigator_e2ee_salt_2026';

  @override
  Future<PairingPayloadModel> generateSenderPairing() async {
    final code = CryptoHelper.generatePairingCode();
    final pairId = 'pair_${CryptoHelper.sha256Hash(code).substring(0, 10)}';
    final sharedSecretBase64 = CryptoHelper.deriveKeyFromCode(code, _salt);
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + (10 * 60 * 1000); // 10 minutes

    return PairingPayloadModel(
      pairId: pairId,
      code: code,
      sharedSecretBase64: sharedSecretBase64,
      createdAt: now,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<bool> confirmSenderPairing(PairingPayloadModel payload) async {
    return await nativeService.setRelayConfig(
      isRelayEnabled: true,
      pairId: payload.pairId,
      sharedSecretBase64: payload.sharedSecretBase64,
    );
  }

  @override
  Future<bool> confirmReceiverPairing(String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.length != 6) return false;

    final pairId = 'pair_${CryptoHelper.sha256Hash(trimmedCode).substring(0, 10)}';
    final sharedSecretBase64 = CryptoHelper.deriveKeyFromCode(trimmedCode, _salt);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReceiverPairId, pairId);
    await prefs.setString(_keyReceiverSharedSecret, sharedSecretBase64);
    await prefs.setString(_keyReceiverPairCode, trimmedCode);

    return true;
  }

  @override
  Future<PairingPayloadModel?> getReceiverPairing() async {
    final prefs = await SharedPreferences.getInstance();
    final pairId = prefs.getString(_keyReceiverPairId);
    final sharedSecret = prefs.getString(_keyReceiverSharedSecret);
    final code = prefs.getString(_keyReceiverPairCode) ?? '';

    if (pairId == null || sharedSecret == null) return null;

    return PairingPayloadModel(
      pairId: pairId,
      code: code,
      sharedSecretBase64: sharedSecret,
      createdAt: 0,
      expiresAt: 0,
    );
  }

  @override
  Future<bool> clearReceiverPairing() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReceiverPairId);
    await prefs.remove(_keyReceiverSharedSecret);
    await prefs.remove(_keyReceiverPairCode);
    return true;
  }
}
