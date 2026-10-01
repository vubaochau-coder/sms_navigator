import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/paired_device_item.dart';

abstract class PairManagementService {
  /// Lấy danh sách các máy nhận đã kết nối với máy gửi hiện tại
  Future<List<PairedDeviceItem>> getPairedReceivers({CancelToken? cancelToken});

  /// Lấy danh sách các máy gửi đã kết nối tới máy nhận hiện tại (Read-only)
  Future<List<PairedDeviceItem>> getPairedSenders({CancelToken? cancelToken});
}

class PairManagementServiceImpl implements PairManagementService {
  final ApiClient apiClient;

  PairManagementServiceImpl({required this.apiClient});

  @override
  Future<List<PairedDeviceItem>> getPairedReceivers({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.pairedReceivers,
        cancelToken: cancelToken,
      );
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
  Future<List<PairedDeviceItem>> getPairedSenders({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.pairedSenders,
        cancelToken: cancelToken,
      );
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
}
