import '../../models/app_update_info_model.dart';
import '../../services/app_update_service.dart';
import '../app_update_repository.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateService _appUpdateService;

  AppUpdateRepositoryImpl({required AppUpdateService appUpdateService})
      : _appUpdateService = appUpdateService;

  @override
  Future<AppUpdateInfoModel?> checkForUpdate() =>
      _appUpdateService.checkForUpdate();

  @override
  Future<void> dismissUpdate(int buildNumber) =>
      _appUpdateService.dismissUpdate(buildNumber);

  @override
  bool isUpdateDismissed(int buildNumber) =>
      _appUpdateService.isUpdateDismissed(buildNumber);
}
