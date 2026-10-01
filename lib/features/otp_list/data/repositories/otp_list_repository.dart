import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/device_storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../../core/utils/data_converter.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../sender/data/services/native_relay_service.dart';
import '../../domain/models/decrypted_otp_item.dart';
import '../models/relay_history_item_model.dart';

abstract class OtpListRepository {
  Future<List<DecryptedOtpItem>> getOtpListForDate(
    DateTime date, {
    String? pairId,
    CancelToken? cancelToken,
  });
}

class OtpListRepositoryImpl implements OtpListRepository {
  final ApiClient apiClient;
  final DeviceStorageService storageService;
  final NativeRelayService nativeRelayService;
  final LocalStorageService localStorageService;

  OtpListRepositoryImpl({
    required this.apiClient,
    required this.storageService,
    required this.nativeRelayService,
    required this.localStorageService,
  });

  @override
  Future<List<DecryptedOtpItem>> getOtpListForDate(
    DateTime date, {
    String? pairId,
    CancelToken? cancelToken,
  }) async {
    // Truy vấn theo dải [from, to] ISO 8601 kèm offset múi giờ thiết bị
    // (toIso8601String tự nhúng +07:00 trên máy VN) để không bị lệch ngày.
    final from = DateTimeUtils.startOfDay(date).toIso8601String();
    final to = DateTimeUtils.endOfDay(date).toIso8601String();

    // Retrieve shared secret and pairId (support both receiver and sender modes)
    String? sharedSecret = localStorageService.getString(
      StorageKeys.receiverSharedSecret,
    );
    String? targetPairId =
        pairId ?? localStorageService.getString(StorageKeys.receiverPairId);

    if (sharedSecret == null || sharedSecret.isEmpty) {
      final senderConfig = await nativeRelayService.getRelayConfig();
      sharedSecret = DataConverter.cvToString(
        senderConfig['sharedSecretBase64'],
      );
      targetPairId ??= DataConverter.cvToString(senderConfig['pairId']);
    }

    final response = await apiClient.get(
      ApiEndpoints.relayHistory,
      queryParameters: {
        'from': from,
        'to': to,
        'pair_id': ?targetPairId,
      },
      cancelToken: cancelToken,
    );
    final rawRecords = DataConverter.cvToList<dynamic>(
      DataConverter.cvToMap<String, dynamic>(response)?['records'],
      (item) => item,
    );

    final List<DecryptedOtpItem> items = [];

    for (final raw in rawRecords) {
      if (raw is! Map<String, dynamic>) continue;
      final model = RelayHistoryItemModel.fromMap(raw);

      String sender = 'Unknown';
      String otp = 'SMS';
      String fullMessage = '';
      DateTime receivedAt =
          model.relayedAt ?? model.sentAt ?? DateTime.now();

      // Nhãn định hướng: tin do chính thiết bị này gửi hay được nhận từ máy gửi
      final isViewerSender = model.viewerRole != 'RECEIVER';
      final String deviceLabel;
      if (isViewerSender) {
        final receiverName = model.receiverDeviceName?.trim();
        deviceLabel =
            (receiverName == null || receiverName.isEmpty || receiverName == 'null')
                ? 'Đã gửi tới Máy Nhận'
                : 'Đã gửi tới $receiverName';
      } else {
        final senderName = model.senderDeviceName?.trim();
        deviceLabel =
            (senderName == null || senderName.isEmpty || senderName == 'null')
                ? 'Nhận từ Máy Gửi'
                : 'Nhận từ $senderName';
      }

      // Attempt decryption if shared secret is available
      if (sharedSecret != null &&
          sharedSecret.isNotEmpty &&
          model.encryptedPayload.isNotEmpty) {
        try {
          final decryptedJson = await CryptoHelper.decryptAesGcm256(
            ciphertextWithTagBase64: model.encryptedPayload,
            ivBase64: model.iv,
            secretKeyBase64: sharedSecret,
          );
          final Map<String, dynamic> data = jsonDecode(decryptedJson);
          sender = DataConverter.cvToString(data['sender'], sender)!;
          otp = DataConverter.cvToString(data['otp'], otp)!;
          fullMessage = DataConverter.cvToString(
            data['fullMessage'] ?? data['full_message'],
            fullMessage,
          )!;
          final parsedTs = DataConverter.cvToDateTime(data['timestamp']);
          if (parsedTs != null) {
            receivedAt = parsedTs;
          }
        } catch (_) {
          // If decryption fails, payload remains hidden for security
          sender = 'Encrypted Service';
          otp = '******';
          fullMessage = '[Nội dung đã được mã hóa đầu-cuối AES-256-GCM]';
        }
      }

      items.add(
        DecryptedOtpItem(
          id: model.id,
          pairId: model.pairId,
          senderDeviceId: model.senderDeviceId,
          senderDeviceName: deviceLabel,
          sender: sender,
          otp: otp,
          fullMessage: fullMessage,
          receivedAt: receivedAt,
          sentAt: model.sentAt,
          status: model.status,
        ),
      );
    }

    // Sort newest first
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return items;
  }
}
