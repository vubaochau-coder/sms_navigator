import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/received_otp_model.dart';

abstract class ReceiverStorageService {
  Future<List<ReceivedOtpModel>> getReceivedOtps();
  Future<void> saveReceivedOtp(ReceivedOtpModel otp);
  Future<void> clearAllOtps();
}

class ReceiverStorageServiceImpl implements ReceiverStorageService {
  static const String _keyOtps = 'received_otps_history';

  @override
  Future<List<ReceivedOtpModel>> getReceivedOtps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOtps);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyOtps,
      jsonEncode(updatedList.map((e) => e.toMap()).toList()),
    );
  }

  @override
  Future<void> clearAllOtps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOtps);
  }
}
