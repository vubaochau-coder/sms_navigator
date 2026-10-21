import '../../constants/api_endpoints.dart';
import '../../models/pairing_request_model.dart';
import '../../network/api_client.dart';
import '../../utils/data_converter.dart';
import '../qr_api_service.dart';

class QrApiServiceImpl implements QrApiService {
  QrApiServiceImpl({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _asMap(dynamic data) =>
      DataConverter.cvToMap<String, dynamic>(data) ?? <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> resolve(String code) async {
    return _asMap(
      await apiClient.get(
        ApiEndpoints.qrResolveV2,
        queryParameters: <String, String>{'code': code},
      ),
    );
  }

  @override
  Future<ClaimRequestResultModel> claimPairingByCode({
    required String code,
    required String deviceName,
  }) async {
    final data = _asMap(
      await apiClient.post(
        ApiEndpoints.pairingClaimV2,
        body: <String, dynamic>{'code': code, 'device_name': deviceName},
      ),
    );
    return ClaimRequestResultModel.fromMap(data);
  }
}
