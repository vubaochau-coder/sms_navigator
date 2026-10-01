import 'dart:convert';
import 'package:flutter/services.dart';

abstract class NativeRelayService {
  Future<Map<String, dynamic>> getRelayConfig();
  Future<bool> setRelayConfig({
    bool? isRelayEnabled,
    String? relayMode,
    List<String>? senderWhitelist,
    String? pairId,
    String? sharedSecretBase64,
    String? relayUrl,
    String? deviceToken,
    String? deviceId,
  });
  Future<List<Map<String, dynamic>>> getRecentLogs();
  Future<bool> clearPairing();
  Future<bool> isBatteryOptimizationIgnored();
  Future<bool> requestIgnoreBatteryOptimization();
  Future<Map<String, dynamic>> getAggressiveRomInfo();
  Future<String?> getDeviceName();
  Future<bool> openAutostartSettings();
  void setOnOtpDetectedListener(Function(String sender, String otp) listener);
}

class NativeRelayServiceImpl implements NativeRelayService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.sms_navigator/relay',
  );

  Function(String sender, String otp)? _otpListener;

  NativeRelayServiceImpl() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onOtpDetected') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final sender = args?['sender']?.toString() ?? 'Unknown';
      final otp = args?['otp']?.toString() ?? '';
      _otpListener?.call(sender, otp);
    }
  }

  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'isAggressiveBatteryRom',
      );
      if (result == null) return {'isAggressive': false, 'oem': null};
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'isAggressive': false, 'oem': null};
    }
  }

  @override
  Future<String?> getDeviceName() async {
    try {
      final result = await _channel.invokeMethod<String>('getDeviceName');
      final name = result?.trim();
      return (name == null || name.isEmpty) ? null : name;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openAutostartSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openAutostartSettings',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void setOnOtpDetectedListener(Function(String sender, String otp) listener) {
    _otpListener = listener;
  }

  @override
  Future<Map<String, dynamic>> getRelayConfig() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getRelayConfig',
      );
      if (result == null) return {};
      final map = Map<String, dynamic>.from(result);
      if (map['senderWhitelist'] is List) {
        map['senderWhitelist'] = (map['senderWhitelist'] as List)
            .map((e) => e.toString())
            .toList();
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<bool> setRelayConfig({
    bool? isRelayEnabled,
    String? relayMode,
    List<String>? senderWhitelist,
    String? pairId,
    String? sharedSecretBase64,
    String? relayUrl,
    String? deviceToken,
    String? deviceId,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (isRelayEnabled != null) params['isRelayEnabled'] = isRelayEnabled;
      if (relayMode != null) params['relayMode'] = relayMode;
      if (senderWhitelist != null) params['senderWhitelist'] = senderWhitelist;
      if (pairId != null) params['pairId'] = pairId;
      if (sharedSecretBase64 != null) {
        params['sharedSecretBase64'] = sharedSecretBase64;
      }
      if (relayUrl != null) params['relayUrl'] = relayUrl;
      if (deviceToken != null) params['deviceToken'] = deviceToken;
      if (deviceId != null) params['deviceId'] = deviceId;

      final success = await _channel.invokeMethod<bool>(
        'setRelayConfig',
        params,
      );
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async {
    try {
      final raw = await _channel.invokeMethod<String>('getRecentLogs');
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> clearPairing() async {
    try {
      final success = await _channel.invokeMethod<bool>('clearPairing');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isBatteryOptimizationIgnored',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimization',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
