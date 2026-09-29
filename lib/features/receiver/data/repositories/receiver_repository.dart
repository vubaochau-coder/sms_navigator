import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../device/data/services/device_api_service.dart';
import '../../../pairing/data/models/pairing_payload_model.dart';
import '../../../pairing/data/services/pairing_service.dart';
import '../models/received_otp_model.dart';
import '../services/receiver_storage_service.dart';

abstract class ReceiverRepository {
  Future<List<ReceivedOtpModel>> fetchReceivedOtps();
  Future<void> addNewOtp(ReceivedOtpModel otp);
  Future<void> clearHistory();
  Future<int> pollPendingOtps();
}

class ReceiverRepositoryImpl implements ReceiverRepository {
  final ReceiverStorageService storageService;
  final PairingService pairingService;
  final ApiClient apiClient;
  final DeviceApiService deviceApiService;

  ReceiverRepositoryImpl({
    required this.storageService,
    required this.pairingService,
    required this.apiClient,
    required this.deviceApiService,
  });

  @override
  Future<List<ReceivedOtpModel>> fetchReceivedOtps() async {
    return await storageService.getReceivedOtps();
  }

  @override
  Future<void> addNewOtp(ReceivedOtpModel otp) async {
    await storageService.saveReceivedOtp(otp);
  }

  @override
  Future<void> clearHistory() async {
    await storageService.clearAllOtps();
  }

  @override
  Future<int> pollPendingOtps() async {
    final PairingPayloadModel? pairing = await pairingService.getReceiverPairing();
    if (pairing == null) return 0;

    await deviceApiService.registerDevice();

    final res = await apiClient.get('/api/v1/relay/pending/${pairing.pairId}');
    final messages = _extractMessages(res);
    if (messages.isEmpty) return 0;

    final existingOtps = await storageService.getReceivedOtps();
    final knownIds = existingOtps.map((e) => e.id).toSet();

    var newCount = 0;
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      try {
        final decrypted = await CryptoHelper.decryptAesGcm256(
          ciphertextWithTagBase64: msg['encrypted_payload']?.toString() ?? '',
          ivBase64: msg['iv']?.toString() ?? '',
          secretKeyBase64: pairing.sharedSecretBase64,
        );

        final model = _parseOtpPayload(
          decrypted,
          messageId: msg['message_id']?.toString(),
          fallbackIndex: i,
        );
        if (knownIds.contains(model.id)) continue;

        await storageService.saveReceivedOtp(model);
        knownIds.add(model.id);
        newCount++;
      } catch (_) {
        // Bỏ qua tin nhắn lỗi định dạng / giải mã thất bại.
      }
    }
    return newCount;
  }

  List<Map<String, dynamic>> _extractMessages(dynamic res) {
    if (res is List) {
      return res.whereType<Map>().map(_normalizeMap).toList();
    }
    if (res is Map) {
      final raw = res['messages'] ?? res['data'];
      if (raw is List) {
        return raw.whereType<Map>().map(_normalizeMap).toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> raw) {
    return Map<String, dynamic>.from(raw);
  }

  /// Parse JSON payload đã giải mã: `{ sender, otp, timestamp, body }`
  /// (tương thích thêm với `fullMessage` từ Android native).
  ReceivedOtpModel _parseOtpPayload(
    String decrypted, {
    String? messageId,
    required int fallbackIndex,
  }) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(decrypted);
      payload = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      payload = <String, dynamic>{};
    }

    final timestamp = (payload['timestamp'] is num)
        ? (payload['timestamp'] as num).toInt()
        : DateTime.now().millisecondsSinceEpoch;
    final messageIdOrDefault =
        (messageId == null || messageId.isEmpty)
            ? 'srv_${DateTime.now().microsecondsSinceEpoch}_$fallbackIndex'
            : messageId;

    return ReceivedOtpModel(
      id: messageIdOrDefault,
      sender: payload['sender']?.toString() ?? 'Unknown',
      otp: payload['otp']?.toString() ?? '',
      receivedAt: timestamp,
      // OTP có hiệu lực 5 phút — khớp ttl_seconds: 300 của Android native.
      expiresAt: timestamp + (5 * 60 * 1000),
      rawMessage: (payload['body'] ?? payload['fullMessage'])?.toString() ?? '',
    );
  }
}
