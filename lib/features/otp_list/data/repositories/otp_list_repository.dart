import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/services/device_storage_service.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../sender/data/services/native_relay_service.dart';
import '../../domain/models/decrypted_otp_item.dart';
import '../models/relay_history_item_model.dart';

abstract class OtpListRepository {
  Future<List<DecryptedOtpItem>> getOtpListForDate(DateTime date, {String? pairId});
}

class OtpListRepositoryImpl implements OtpListRepository {
  final RestClient restClient;
  final DeviceStorageService storageService;
  final NativeRelayService nativeRelayService;

  OtpListRepositoryImpl({
    required this.restClient,
    required this.storageService,
    required this.nativeRelayService,
  });

  @override
  Future<List<DecryptedOtpItem>> getOtpListForDate(DateTime date, {String? pairId}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Retrieve shared secret and pairId (support both receiver and sender modes)
    final prefs = await SharedPreferences.getInstance();
    String? sharedSecret = prefs.getString('receiver_shared_secret');
    String? targetPairId = pairId ?? prefs.getString('receiver_pair_id');

    if (sharedSecret == null || sharedSecret.isEmpty) {
      final senderConfig = await nativeRelayService.getRelayConfig();
      sharedSecret = senderConfig['sharedSecretBase64']?.toString();
      targetPairId ??= senderConfig['pairId']?.toString();
    }

    final response = await restClient.getRelayHistory(dateStr, targetPairId);
    final List<dynamic> rawRecords = (response is Map)
        ? (response['records'] as List<dynamic>? ?? [])
        : [];

    final List<DecryptedOtpItem> items = [];

    for (final raw in rawRecords) {
      if (raw is! Map<String, dynamic>) continue;
      final model = RelayHistoryItemModel.fromMap(raw);

      String sender = 'Unknown';
      String otp = 'SMS';
      String fullMessage = '';
      DateTime receivedAt = DateTime.fromMillisecondsSinceEpoch(
        model.relayedAt > 0 ? model.relayedAt * 1000 : model.sentAt * 1000,
      );

      // Attempt decryption if shared secret is available
      if (sharedSecret != null && sharedSecret.isNotEmpty && model.encryptedPayload.isNotEmpty) {
        try {
          final decryptedJson = await CryptoHelper.decryptAesGcm256(
            ciphertextWithTagBase64: model.encryptedPayload,
            ivBase64: model.iv,
            secretKeyBase64: sharedSecret,
          );
          final Map<String, dynamic> data = jsonDecode(decryptedJson);
          sender = data['sender']?.toString() ?? sender;
          otp = data['otp']?.toString() ?? otp;
          fullMessage = data['fullMessage']?.toString() ?? data['full_message']?.toString() ?? '';
          if (data['timestamp'] != null) {
            final ts = data['timestamp'];
            if (ts is int) {
              receivedAt = DateTime.fromMillisecondsSinceEpoch(ts > 10000000000 ? ts : ts * 1000);
            }
          }
        } catch (_) {
          // If decryption fails, payload remains hidden for security
          sender = 'Encrypted Service';
          otp = '******';
          fullMessage = '[Nội dung đã được mã hóa đầu-cuối AES-256-GCM]';
        }
      }

      items.add(DecryptedOtpItem(
        id: model.id,
        pairId: model.pairId,
        senderDeviceId: model.senderDeviceId,
        senderDeviceName: model.senderDeviceName ?? 'Máy Gửi (Sender)',
        sender: sender,
        otp: otp,
        fullMessage: fullMessage,
        receivedAt: receivedAt,
        sentAtSeconds: model.sentAt,
        status: model.status,
      ));
    }

    // Sort newest first
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return items;
  }
}
