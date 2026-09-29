import '../models/received_otp_model.dart';
import '../services/receiver_storage_service.dart';

abstract class ReceiverRepository {
  Future<List<ReceivedOtpModel>> fetchReceivedOtps();
  Future<void> addNewOtp(ReceivedOtpModel otp);
  Future<void> clearHistory();
}

class ReceiverRepositoryImpl implements ReceiverRepository {
  final ReceiverStorageService storageService;

  ReceiverRepositoryImpl({required this.storageService});

  @override
  Future<List<ReceivedOtpModel>> fetchReceivedOtps() async {
    return await storageService.getReceivedOtps();
  }

  @override
  Future<void> addNewOtp(ReceivedOtpModel otp) async {
    await storageService.saveReceivedOtp(otp);
  }

  @override
  Future<void> clearHistory() async {
    await storageService.clearAllOtps();
  }
}
