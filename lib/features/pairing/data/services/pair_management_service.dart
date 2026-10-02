import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/data_converter.dart';
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
      return _mapDeviceList(
        response,
        'receivers',
        PairedDeviceItem.fromReceiverJson,
      );
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
      return _mapDeviceList(
        response,
        'senders',
        PairedDeviceItem.fromSenderJson,
      );
    } catch (_) {
      return [];
    }
  }

  /// Chuẩn hóa payload danh sách từ server về danh sách [PairedDeviceItem]
  /// thông qua DataConverter (cvToMap + cvToList), bỏ qua phần tử lỗi.
  static List<PairedDeviceItem> _mapDeviceList(
    dynamic response,
    String listKey,
    PairedDeviceItem Function(Map<String, dynamic>) fromJson,
  ) {
    final payload = DataConverter.cvToMap<String, dynamic>(response);
    final rawList = DataConverter.cvToList<dynamic>(
      payload?[listKey],
      (item) => item,
    );
    return rawList
        .map((e) => DataConverter.cvToMap<String, dynamic>(e))
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}
