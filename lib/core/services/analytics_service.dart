import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý sự kiện và hành vi người dùng bằng Firebase Analytics.
/// Cung cấp các methods có định danh rõ ràng cho ứng dụng SMS Navigator.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();

  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  bool get isAvailable => _analytics != null;

  FirebaseAnalyticsObserver? get observer => _observer;

  /// Khởi tạo Firebase Analytics
  void initialize() {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint(
          'AnalyticsService: Firebase not initialized, analytics disabled.',
        );
        return;
      }
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      debugPrint('AnalyticsService initialized successfully.');
    } catch (e) {
      debugPrint('AnalyticsService initialization failed: $e');
    }
  }

  /// Bắn sự kiện tùy chỉnh
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      if (_analytics == null) return;
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('AnalyticsService.logEvent failed: $e');
    }
  }

  /// Sự kiện: Người dùng chọn Role (SENDER / RECEIVER)
  Future<void> logRoleSelected(String role) async {
    await logEvent('role_selected', parameters: {'role': role});
  }

  /// Sự kiện: Ghép đôi thiết bị thành công
  Future<void> logPairDeviceSuccess({
    required String role,
    required String pairId,
  }) async {
    await logEvent(
      'pair_device_success',
      parameters: {'role': role, 'pair_id': pairId},
    );
  }

  /// Sự kiện: SMS/OTP được phát hiện và relay
  Future<void> logOtpRelayed({
    required String senderPhone,
    required int otpLength,
  }) async {
    await logEvent(
      'otp_relayed',
      parameters: {'sender_phone': senderPhone, 'otp_length': otpLength},
    );
  }

  /// Sự kiện: Bật/Tắt dịch vụ chuyển tiếp SMS
  Future<void> logRelayToggled(bool isEnabled) async {
    await logEvent(
      'relay_toggled',
      parameters: {'is_enabled': isEnabled ? 1 : 0},
    );
  }

  /// Sự kiện: Đổi chế độ chuyển tiếp (OTP_ONLY / ALL_SMS)
  Future<void> logRelayModeChanged(String mode) async {
    await logEvent('relay_mode_changed', parameters: {'mode': mode});
  }

  /// Sự kiện: Đổi URL máy chủ backend
  Future<void> logServerUrlUpdated(String url) async {
    await logEvent('server_url_updated', parameters: {'server_url': url});
  }

  /// Thiết lập ID thiết bị / người dùng
  Future<void> setUserId(String? userId) async {
    try {
      if (_analytics == null) return;
      await _analytics!.setUserId(id: userId);
    } catch (_) {}
  }
}
