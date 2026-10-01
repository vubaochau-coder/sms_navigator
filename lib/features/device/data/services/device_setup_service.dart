import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../sender/data/services/native_relay_service.dart';

abstract class DeviceSetupService {
  Future<bool> isSmsPermissionGranted();
  Future<bool> isSmsPermissionPermanentlyDenied();
  Future<bool> requestSmsPermission();
  Future<bool> openAppSettings();
  Future<bool> isBatteryOptimizationIgnored();
  Future<bool> requestIgnoreBatteryOptimization();
  Future<Map<String, dynamic>> getAggressiveRomInfo();
  Future<bool> openAutostartSettings();
  Future<bool> isAutostartAcknowledged();
  Future<bool> acknowledgeAutostart();
  Future<bool> shouldPromptSmsPermission();
  Future<bool> setDontPromptDeviceSetup();
}

class DeviceSetupServiceImpl implements DeviceSetupService {
  final NativeRelayService nativeRelayService;

  static const String _keyAutostartAck = 'device_setup_autostart_ack';
  static const String _keyDontPrompt = 'device_setup_dont_prompt_dialog';

  DeviceSetupServiceImpl({required this.nativeRelayService});

  @override
  Future<bool> isSmsPermissionGranted() async {
    try {
      final status = await ph.Permission.sms.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isSmsPermissionPermanentlyDenied() async {
    try {
      final status = await ph.Permission.sms.status;
      return status.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestSmsPermission() async {
    try {
      var status = await ph.Permission.sms.status;
      if (!status.isGranted) {
        status = await ph.Permission.sms.request();
      }
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      return await nativeRelayService.isBatteryOptimizationIgnored();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      return await nativeRelayService.requestIgnoreBatteryOptimization();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() async {
    try {
      return await nativeRelayService.getAggressiveRomInfo();
    } catch (_) {
      return {'isAggressive': false, 'oem': null};
    }
  }

  @override
  Future<bool> openAutostartSettings() async {
    try {
      return await nativeRelayService.openAutostartSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isAutostartAcknowledged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAutostartAck) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> acknowledgeAutostart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutostartAck, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> shouldPromptSmsPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyDontPrompt) == true) return false;

      final granted = await isSmsPermissionGranted();
      if (granted) return false;

      final config = await nativeRelayService.getRelayConfig();
      final pairId = config['pairId']?.toString() ?? '';
      final isSenderActive = config['isRelayEnabled'] == true && pairId.isNotEmpty;
      if (isSenderActive) return true;

      final isReceiverPaired =
          (prefs.getString('receiver_pair_id') ?? '').isNotEmpty;
      return !isReceiverPaired;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setDontPromptDeviceSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDontPrompt, true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
