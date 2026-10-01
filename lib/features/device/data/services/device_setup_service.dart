import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
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
  final LocalStorageService localStorageService;

  DeviceSetupServiceImpl({
    required this.nativeRelayService,
    required this.localStorageService,
  });

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
      return localStorageService.getBool(StorageKeys.autostartAcknowledged) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> acknowledgeAutostart() async {
    try {
      await localStorageService.setBool(StorageKeys.autostartAcknowledged, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> shouldPromptSmsPermission() async {
    try {
      if (localStorageService.getBool(StorageKeys.dontPromptPermission) ==
          true) {
        return false;
      }

      final granted = await isSmsPermissionGranted();
      if (granted) return false;

      final config = await nativeRelayService.getRelayConfig();
      final pairId = config['pairId']?.toString() ?? '';
      final isSenderActive = config['isRelayEnabled'] == true && pairId.isNotEmpty;
      if (isSenderActive) return true;

      final isReceiverPaired = (localStorageService.getString(
                StorageKeys.receiverPairId,
              ) ??
              '')
          .isNotEmpty;
      return !isReceiverPaired;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setDontPromptDeviceSetup() async {
    try {
      await localStorageService.setBool(StorageKeys.dontPromptPermission, true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
