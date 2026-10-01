import 'dart:convert';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../models/received_otp_model.dart';

abstract class ReceiverStorageService {
  Future<List<ReceivedOtpModel>> getReceivedOtps();
  Future<void> saveReceivedOtp(ReceivedOtpModel otp);
  Future<void> clearAllOtps();
}

class ReceiverStorageServiceImpl implements ReceiverStorageService {
  ReceiverStorageServiceImpl(this.localStorage);

  final LocalStorageService localStorage;

  @override
  Future<List<ReceivedOtpModel>> getReceivedOtps() async {
    final raw = localStorage.getString(StorageKeys.receivedOtpsHistory);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((e) => ReceivedOtpModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveReceivedOtp(ReceivedOtpModel otp) async {
    final currentList = await getReceivedOtps();
    // Prepend new OTP, limit to 50 entries
    final updatedList = [otp, ...currentList.take(49)];
    await localStorage.setString(
      StorageKeys.receivedOtpsHistory,
      jsonEncode(updatedList.map((e) => e.toMap()).toList()),
    );
  }

  @override
  Future<void> clearAllOtps() {
    return localStorage.remove(StorageKeys.receivedOtpsHistory);
  }
}
