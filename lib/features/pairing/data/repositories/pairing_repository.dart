import '../models/pairing_payload_model.dart';
import '../services/pairing_service.dart';

abstract class PairingRepository {
  Future<PairingPayloadModel> createSenderPairingSession();
  Future<bool> applySenderPairing(PairingPayloadModel payload);
  Future<bool> submitReceiverPairingQr(String qrData);
  Future<bool> submitReceiverPairingCode(String code);
  Future<PairingPayloadModel?> checkReceiverPairingStatus();
  Future<bool> disconnectReceiver();
}

class PairingRepositoryImpl implements PairingRepository {
  final PairingService pairingService;

  PairingRepositoryImpl({required this.pairingService});

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
}
