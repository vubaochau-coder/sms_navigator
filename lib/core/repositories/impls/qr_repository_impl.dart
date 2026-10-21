import '../../models/invite_preview_model.dart';
import '../../models/pairing_request_model.dart';
import '../../models/qr_resolution.dart';
import '../../network/api_client.dart';
import '../../services/device_storage_service.dart';
import '../../services/qr_api_service.dart';
import '../../utils/data_converter.dart';
import '../../utils/qr_link_parser.dart';
import '../qr_repository.dart';

class QrRepositoryImpl implements QrRepository {
  QrRepositoryImpl({
    required QrApiService qrApiService,
    required DeviceStorageService deviceStorage,
  }) : _api = qrApiService,
       _deviceStorage = deviceStorage;

  final QrApiService _api;
  final DeviceStorageService _deviceStorage;

  @override
  Future<Set<String>> allowedLinkHosts() async {
    final hosts = <String>{};
    final configured = QrLinkParser.hostOf(await _deviceStorage.getServerUrl());
    if (configured != null) hosts.add(configured);
    final fallback = QrLinkParser.hostOf(ApiClient.defaultBaseUrl);
    if (fallback != null) hosts.add(fallback);
    return hosts;
  }

  @override
  Future<QrResolution> resolve(String code) async {
    final body = await _api.resolve(code);
    final type = DataConverter.cvToString(body['type'], '')!;
    if (type != 'PAIRING') return UnsupportedQrResolution(type);

    final data = DataConverter.cvToMap<String, dynamic>(body['data']) ?? <String, dynamic>{};
    return PairingQrResolution(code: code, preview: InvitePreviewModel.fromMap(data));
  }

  @override
  Future<ClaimRequestResultModel> claimPairing({
    required String code,
    required String deviceName,
  }) => _api.claimPairingByCode(code: code, deviceName: deviceName);
}
