import '../models/pairing_request_model.dart';

/// Service API Universal Opaque QR (roadmap v3.3 §2.3).
abstract class QrApiService {
  /// `GET /api/v2/qr/resolve?code=` — trả body thô `{type, version, data}`.
  Future<Map<String, dynamic>> resolve(String code);

  /// `POST /api/v2/pairing/requests { code, device_name }`.
  Future<ClaimRequestResultModel> claimPairingByCode({
    required String code,
    required String deviceName,
  });
}
