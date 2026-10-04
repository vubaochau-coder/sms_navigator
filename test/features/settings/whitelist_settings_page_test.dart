import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/core/storage/storage_keys.dart';
import 'package:sms_navigator/core/widgets/app_switch.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/repositories/whitelist_repository.dart';
import 'package:sms_navigator/core/services/native_relay_service.dart';
import 'package:sms_navigator/features/settings/whitelist_settings_page.dart';
import 'package:sms_navigator/features/settings/views/whitelist_blocked_banner.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeWhitelistRepository implements WhitelistRepository {
  _FakeWhitelistRepository({WhitelistConfigModel? initial})
      : stored = initial ?? const WhitelistConfigModel();

  WhitelistConfigModel stored;
  bool shouldFailSave = false;

  @override
  Future<WhitelistConfigModel> getWhitelist() async => stored;

  @override
  Future<bool> saveWhitelist(WhitelistConfigModel config) async {
    if (shouldFailSave) return false;
    stored = config;
    return true;
  }
}

class _FakeNativeRelayService implements NativeRelayService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalStorageService implements LocalStorageService {
  _FakeLocalStorageService({this.receiverPairId});

  final String? receiverPairId;

  @override
  String? getString(String key) =>
      key == StorageKeys.receiverPairId ? receiverPairId : null;

  @override
  Future<void> setString(String key, String value) async {}

  @override
  bool? getBool(String key) => null;

  @override
  Future<void> setBool(String key, bool value) async {}

  @override
  Future<void> remove(String key) async {}
}

Future<void> _pumpSettingsPage(
  WidgetTester tester,
  WhitelistRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepositoryProvider<WhitelistRepository>.value(
        value: repository,
        child: const WhitelistSettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WhitelistSettingsPage', () {
    testWidgets('shows warning banner when whitelist blocks everything',
        (tester) async {
      await _pumpSettingsPage(tester, _FakeWhitelistRepository());

      expect(find.text('Chưa cấu hình bộ lọc gửi'), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });

    testWidgets('hides warning banner when entries exist', (tester) async {
      final repo = _FakeWhitelistRepository(
        initial: const WhitelistConfigModel(
          entries: [WhitelistEntryModel(address: 'VCB')],
        ),
      );
      await _pumpSettingsPage(tester, repo);

      expect(find.text('Chưa cấu hình bộ lọc gửi'), findsNothing);
      expect(find.text('VCB'), findsOneWidget);
    });

    testWidgets('entry checkbox toggles allowOtp via bloc', (tester) async {
      final repo = _FakeWhitelistRepository(
        initial: const WhitelistConfigModel(
          entries: [WhitelistEntryModel(address: 'VCB')],
        ),
      );
      await _pumpSettingsPage(tester, repo);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(repo.stored.entries.first.allowOtp, isTrue);
    });

    testWidgets('all-addresses switch persists mode change', (tester) async {
      final repo = _FakeWhitelistRepository();
      await _pumpSettingsPage(tester, repo);

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      expect(repo.stored.mode, WhitelistMode.allAddresses);
    });
  });

  group('WhitelistBlockedBanner', () {
    testWidgets('shows on sender device when whitelist is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<NativeRelayService>(
                create: (_) => _FakeNativeRelayService(),
              ),
              RepositoryProvider<LocalStorageService>(
                create: (_) => _FakeLocalStorageService(),
              ),
            ],
            child: const Scaffold(body: WhitelistBlockedBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Tin nhắn SMS đang tạm dừng chuyển tiếp để bảo vệ an toàn dữ liệu. Thêm địa chỉ bạn muốn chuyển tiếp.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('hides on receiver-paired device', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<NativeRelayService>(
                create: (_) => _FakeNativeRelayService(),
              ),
              RepositoryProvider<LocalStorageService>(
                create: (_) => _FakeLocalStorageService(receiverPairId: 'p1'),
              ),
            ],
            child: const Scaffold(body: WhitelistBlockedBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('đang bị chặn'), findsNothing);
    });
  });
}
