import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/app_update_info_model.dart';
import '../../storage/local_storage_service.dart';
import '../../storage/storage_keys.dart';
import '../../utils/app_logger.dart';
import '../app_update_service.dart';

class AppUpdateServiceImpl implements AppUpdateService {
  FirebaseRemoteConfig? _remoteConfig;
  final LocalStorageService _localStorage;

  AppUpdateServiceImpl({
    FirebaseRemoteConfig? remoteConfig,
    required LocalStorageService localStorage,
  })  : _remoteConfig = remoteConfig,
        _localStorage = localStorage;

  FirebaseRemoteConfig? get _effectiveRemoteConfig {
    if (_remoteConfig != null) return _remoteConfig;
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      return _remoteConfig;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUpdateInfoModel?> checkForUpdate() async {
    try {
      final config = _effectiveRemoteConfig;
      if (config == null) {
        return null;
      }

      // 1. Cấu hình timeout và interval lấy dữ liệu mới nhất
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));

      // 2. Giá trị mặc định an toàn (không hardcode URL cụ thể ở client)
      await config.setDefaults(<String, dynamic>{
        'app_update_latest_build': 0,
        'app_update_latest_version': '',
        'app_update_min_build': 0,
        'app_update_title': '',
        'app_update_description': '',
        'app_update_download_url': '',
      });

      // 3. Kéo và kích hoạt dữ liệu từ Firebase Remote Config
      await config.fetchAndActivate();

      // 4. Lấy thông tin phiên bản hiện tại của app
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final currentVersion = packageInfo.version;

      // 5. Đọc các tham số đã cấu hình từ Remote Config
      final latestBuild = config.getInt('app_update_latest_build');
      final latestVersion = config.getString('app_update_latest_version');
      final minBuild = config.getInt('app_update_min_build');
      final title = config.getString('app_update_title');
      final description = config.getString('app_update_description');
      final downloadUrl = config.getString('app_update_download_url');

      AppLogger.i(
        'AppUpdateService',
        'Current: $currentVersion+$currentBuild | Remote: $latestVersion+$latestBuild (min: $minBuild)',
      );

      // 6. Đánh giá thông tin cập nhật qua hàm thuần
      return AppUpdateInfoModel.evaluate(
        currentBuild: currentBuild,
        currentVersion: currentVersion,
        latestBuild: latestBuild,
        latestVersion: latestVersion,
        minBuild: minBuild,
        title: title,
        description: description,
        downloadUrl: downloadUrl,
      );
    } catch (e, stack) {
      AppLogger.w('AppUpdateService', 'checkForUpdate error', e, stack);
      return null;
    }
  }

  @override
  Future<void> dismissUpdate(int buildNumber) async {
    await _localStorage.setString(
      StorageKeys.lastDismissedAppUpdateBuild,
      buildNumber.toString(),
    );
  }

  @override
  bool isUpdateDismissed(int buildNumber) {
    final dismissed = _localStorage.getString(
      StorageKeys.lastDismissedAppUpdateBuild,
    );
    return dismissed == buildNumber.toString();
  }
}
