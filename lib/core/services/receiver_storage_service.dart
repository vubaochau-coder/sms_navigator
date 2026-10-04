import '../models/received_otp_model.dart';

abstract class ReceiverStorageService {
  Future<List<ReceivedOtpModel>> getReceivedOtps();
  Future<void> saveReceivedOtp(ReceivedOtpModel otp);
  Future<void> clearAllOtps();
}
