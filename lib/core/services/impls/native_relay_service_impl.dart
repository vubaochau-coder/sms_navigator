import 'dart:convert';
import 'package:flutter/services.dart';

import '../../models/whitelist_config_model.dart';
import '../../utils/data_converter.dart';
import '../native_relay_service.dart';

class NativeRelayServiceImpl implements NativeRelayService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.sms_navigator/relay',
  );

  NativeRelayServiceImpl() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    // Hiện không có native-to-Dart callback nào đang được sử dụng.
    return null;
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
