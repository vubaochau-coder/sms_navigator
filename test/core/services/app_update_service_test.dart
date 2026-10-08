import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/models/app_update_info_model.dart';
import 'package:sms_navigator/core/repositories/impls/app_update_repository_impl.dart';
import 'package:sms_navigator/core/services/impls/app_update_service_impl.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService localStorage;
  late AppUpdateServiceImpl appUpdateService;
  late AppUpdateRepositoryImpl appUpdateRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    localStorage = await LocalStorageService.create();
    appUpdateService = AppUpdateServiceImpl(localStorage: localStorage);
    appUpdateRepository = AppUpdateRepositoryImpl(appUpdateService: appUpdateService);
  });

  group('AppUpdateInfoModel.evaluate (Pure Logic Matrix)', () {
    test('returns null when latestBuild is lower than currentBuild', () {
      final result = AppUpdateInfoModel.evaluate(
        currentBuild: 15,
        currentVersion: '0.0.1',
        latestBuild: 14,
        latestVersion: '0.0.1',
        minBuild: 10,
        title: 'Update',
        description: 'Notes',
        downloadUrl: 'https://example.com',
      );

      expect(result, isNull);
    });

    test('returns null when latestBuild equals currentBuild', () {
      final result = AppUpdateInfoModel.evaluate(
        currentBuild: 15,
        currentVersion: '0.0.1',
        latestBuild: 15,
        latestVersion: '0.0.1',
        minBuild: 10,
        title: 'Update',
        description: 'Notes',
        downloadUrl: 'https://example.com',
      );

      expect(result, isNull);
    });

    test('returns optional update when latestBuild > currentBuild and currentBuild >= minBuild', () {
      final result = AppUpdateInfoModel.evaluate(
        currentBuild: 15,
        currentVersion: '0.0.1',
        latestBuild: 16,
        latestVersion: '0.0.2',
        minBuild: 15,
        title: 'Có bản mới',
        description: 'Fix lỗi',
        downloadUrl: 'https://example.com',
      );

      expect(result, isNotNull);
      expect(result!.latestBuild, 16);
      expect(result.latestVersion, '0.0.2');
      expect(result.isForceUpdate, isFalse);
    });

    test('returns force update when currentBuild < minBuild', () {
      final result = AppUpdateInfoModel.evaluate(
        currentBuild: 14,
        currentVersion: '0.0.1',
        latestBuild: 16,
        latestVersion: '0.0.2',
        minBuild: 15,
        title: 'Bắt buộc cập nhật',
        description: 'Yêu cầu bảo mật',
        downloadUrl: 'https://example.com',
      );

      expect(result, isNotNull);
      expect(result!.isForceUpdate, isTrue);
    });

    test('falls back to currentVersion when latestVersion is blank', () {
      final result = AppUpdateInfoModel.evaluate(
        currentBuild: 10,
        currentVersion: '0.0.1',
        latestBuild: 12,
        latestVersion: '   ',
        minBuild: 0,
        title: 'Title',
        description: 'Desc',
        downloadUrl: 'https://example.com',
      );

      expect(result, isNotNull);
      expect(result!.latestVersion, '0.0.1');
    });
  });

  group('AppUpdateService & Repository Dismissal', () {
    test('isUpdateDismissed returns false initially and true after dismissUpdate', () async {
      expect(appUpdateRepository.isUpdateDismissed(16), isFalse);

      await appUpdateRepository.dismissUpdate(16);

      expect(appUpdateRepository.isUpdateDismissed(16), isTrue);
      expect(appUpdateRepository.isUpdateDismissed(17), isFalse);
    });
  });
}
