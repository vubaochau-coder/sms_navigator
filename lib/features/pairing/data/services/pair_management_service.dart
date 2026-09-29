import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/paired_device_item.dart';

abstract class PairManagementService {
  /// Lấy danh sách các máy nhận đã kết nối với máy gửi hiện tại
  Future<List<PairedDeviceItem>> getPairedReceivers();

  /// Lấy danh sách các máy gửi đã kết nối tới máy nhận hiện tại (Read-only)
  Future<List<PairedDeviceItem>> getPairedSenders();

  /// Phía máy gửi bật/tắt quyền chuyển tiếp OTP tới máy nhận
  Future<bool> togglePairActive({
    required String pairId,
    required bool isActive,
  });

  /// Hủy ghép đôi một cặp
  Future<bool> revokePair(String pairId);
}

class PairManagementServiceImpl implements PairManagementService {
  final ApiClient apiClient;

  PairManagementServiceImpl({required this.apiClient});

  @override
  Future<List<PairedDeviceItem>> getPairedReceivers() async {
    try {
      final response = await apiClient.get(ApiEndpoints.pairedReceivers);
      if (response is Map<String, dynamic> && response['receivers'] is List) {
        final list = response['receivers'] as List<dynamic>;
        return list
            .whereType<Map<String, dynamic>>()
            .map(PairedDeviceItem.fromReceiverJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<PairedDeviceItem>> getPairedSenders() async {
    try {
      final response = await apiClient.get(ApiEndpoints.pairedSenders);
      if (response is Map<String, dynamic> && response['senders'] is List) {
        final list = response['senders'] as List<dynamic>;
        return list
            .whereType<Map<String, dynamic>>()
            .map(PairedDeviceItem.fromSenderJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> togglePairActive({
    required String pairId,
    required bool isActive,
  }) async {
    try {
      final path = ApiEndpoints.togglePairPath(pairId);
      final response = await apiClient.dio.patch<dynamic>(
        path,
        data: {'is_active': isActive},
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> revokePair(String pairId) async {
    try {
      final path = ApiEndpoints.revokePairPath(pairId);
      final response = await apiClient.delete(path);
      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
