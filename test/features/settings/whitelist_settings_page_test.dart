import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/widgets/app_switch.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/repositories/whitelist_repository.dart';
import 'package:sms_navigator/features/settings/whitelist_settings_page.dart';
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

  List<Map<String, dynamic>> logs = const [];

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async => logs;
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

    testWidgets('tapping receipt icon opens relay log sheet and shows empty view',
        (tester) async {
      final repo = _FakeWhitelistRepository();
      await _pumpSettingsPage(tester, repo);

      await tester.tap(find.byIcon(Icons.receipt_long_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Nhật ký tiếp nhận SMS'), findsOneWidget);
      expect(find.text('Chưa có SMS nào được ghi nhận.'), findsOneWidget);
    });

    testWidgets('tapping receipt icon opens relay log sheet and displays log items',
        (tester) async {
      final repo = _FakeWhitelistRepository();
      repo.logs = [
        {
          'id': 'log-1',
          'sender': 'SSO',
          'otp': '123456',
          'status': 'FAILED',
          'error': 'HTTP 401: Unauthorized',
          'timestamp': 1728300000000,
        }
      ];
      await _pumpSettingsPage(tester, repo);

      await tester.tap(find.byIcon(Icons.receipt_long_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Nhật ký tiếp nhận SMS'), findsOneWidget);
      expect(find.text('SSO'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('HTTP 401: Unauthorized'), findsOneWidget);
      expect(find.text('Nội dung phát hiện: 123456'), findsOneWidget);
    });
  });
}
