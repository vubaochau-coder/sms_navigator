import 'dart:convert';
import 'package:flutter/services.dart';

import '../../models/whitelist_config_model.dart';
import '../../utils/data_converter.dart';
import '../native_relay_service.dart';

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
      final args = DataConverter.cvToMap<String, dynamic>(call.arguments);
      final sender = DataConverter.cvToString(args?['sender'], 'Unknown')!;
      final otp = DataConverter.cvToString(args?['otp'], '')!;
      _otpListener?.call(sender, otp);
    }
  }

  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'isAggressiveBatteryRom',
      );
      return DataConverter.cvToMap<String, dynamic>(result) ??
          {'isAggressive': false, 'oem': null};
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
      return DataConverter.cvToMap<String, dynamic>(result) ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<bool> setRelayConfig({
    bool? isRelayEnabled,
    String? pairId,
    String? sharedSecretBase64,
    String? relayUrl,
    String? deviceToken,
    String? deviceId,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (isRelayEnabled != null) params['isRelayEnabled'] = isRelayEnabled;
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
  Future<WhitelistConfigModel> getWhitelist() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getWhitelist',
      );
      final map = DataConverter.cvToMap<String, dynamic>(result);
      if (map == null) return const WhitelistConfigModel();
      return WhitelistConfigModel.fromMap(map);
    } catch (_) {
      return const WhitelistConfigModel();
    }
  }

  @override
  Future<bool> setWhitelist(WhitelistConfigModel config) async {
    try {
      final success = await _channel.invokeMethod<bool>(
        'setWhitelist',
        config.toMap(),
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
      return decoded
          .map((e) => DataConverter.cvToMap<String, dynamic>(e))
          .whereType<Map<String, dynamic>>()
          .toList();
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
  Future<bool> setActiveRelayChannel({
    required String channelId,
    required String channelName,
    required int keyEpoch,
    required String channelKeyBase64,
    required String deviceToken,
    String? apiBaseUrl,
  }) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'setActiveRelayChannel',
        {
          'channelId': channelId,
          'channelName': channelName,
          'keyEpoch': keyEpoch,
          'channelKeyBase64': channelKeyBase64,
          'deviceToken': deviceToken,
          if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) 'apiBaseUrl': apiBaseUrl,
        },
      );
      if (result is Map) {
        return result['updated'] == true;
      }
      return result == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> clearActiveRelayChannel() async {
    try {
      final success = await _channel.invokeMethod<bool>('clearActiveRelayChannel');
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
