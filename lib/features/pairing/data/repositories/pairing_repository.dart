import '../models/pairing_payload_model.dart';
import '../services/pairing_service.dart';
import '../services/qr_image_export_service.dart';

abstract class PairingRepository {
  Future<PairingPayloadModel> createSenderPairingSession();
  Future<bool> applySenderPairing(PairingPayloadModel payload);
  Future<bool> submitReceiverPairingQr(String qrData);
  Future<bool> submitReceiverPairingCode(String code);
  Future<PairingPayloadModel?> checkReceiverPairingStatus();
  Future<bool> disconnectReceiver();
  Future<void> exportPairingQr(PairingPayloadModel payload);
}

class PairingRepositoryImpl implements PairingRepository {
  final PairingService pairingService;
  final QrImageExportService qrImageExportService;

  PairingRepositoryImpl({
    required this.pairingService,
    required this.qrImageExportService,
  });

  @override
  Future<PairingPayloadModel> createSenderPairingSession() async {
    final payload = await pairingService.generateSenderPairing();
    await pairingService.confirmSenderPairing(payload);
    return payload;
  }

  @override
  Future<bool> applySenderPairing(PairingPayloadModel payload) async {
    return await pairingService.confirmSenderPairing(payload);
  }

  @override
  Future<bool> submitReceiverPairingQr(String qrData) async {
    return await pairingService.confirmReceiverPairingFromQr(qrData);
  }

  @override
  Future<bool> submitReceiverPairingCode(String code) async {
    return await submitReceiverPairingQr(code);
  }

  @override
  Future<PairingPayloadModel?> checkReceiverPairingStatus() async {
    return await pairingService.getReceiverPairing();
  }

  @override
  Future<bool> disconnectReceiver() async {
    return await pairingService.clearReceiverPairing();
  }

  @override
  Future<void> exportPairingQr(PairingPayloadModel payload) async {
    final bytes = await qrImageExportService.renderQrPng(
      data: payload.toQrData(),
      size: 512,
      title: 'Mã QR ghép đôi SMS Navigator',
      subtitle: 'Quét mã bằng SMS Navigator để ghép đôi thiết bị',
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await qrImageExportService.saveToGallery(
      bytes,
      fileName:
          'sms_navigator_pair_qr_${_safeFileToken(payload.pairId)}_$timestamp',
    );
  }

  /// Hậu tố pairId dùng trong tên file, chỉ giữ chữ/số/gạch dưới.
  String _safeFileToken(String pairId) {
    final suffix =
        pairId.length > 8 ? pairId.substring(pairId.length - 8) : pairId;
    return suffix.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '-');
  }
}
