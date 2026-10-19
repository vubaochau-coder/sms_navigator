import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/core/widgets/app_switch.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/whitelist_repository.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/utils/channel_crypto_helper.dart';
import 'package:sms_navigator/features/settings/whitelist_settings_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeWhitelistRepository implements WhitelistRepository {
  _FakeWhitelistRepository({WhitelistConfigModel? initial})
      : stored = initial ?? const WhitelistConfigModel();

  WhitelistConfigModel stored;
  bool shouldFailSave = false;

  @override
  Future<WhitelistConfigModel> getWhitelist(String channelId) async => stored;

  @override
  Future<bool> saveWhitelist({
    required String channelId,
    required WhitelistConfigModel config,
    required int keyEpoch,
    required String channelKeyBase64,
  }) async {
    if (shouldFailSave) return false;
    stored = config;
    return true;
  }

  @override
  Future<WhitelistConfigModel?> syncWhitelistFromServer({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    required ChannelWhitelistBlobModel blob,
  }) async => stored;

  List<Map<String, dynamic>> logs = const [];

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async => logs;
}

class _FakeChannelRepository implements ChannelRepository {
  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) async {
    return const ChannelDetailModel(
      channelId: 'test_channel',
      name: 'Kênh thử nghiệm',
      myRole: ChannelRole.owner,
      status: 'ACTIVE',
      currentEpoch: 1,
      myStatus: 'ACTIVE',
    );
  }

  @override
  Future<List<ChannelModel>> listChannels() async => [];
  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) async => [];
  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) async => [];
  @override
  Future<ChannelModel> createChannel(String name) async => throw UnimplementedError();
  @override
  Future<int> approveRequest({required String channelId, required PairingRequestModel request}) async => 1;
  @override
  Future<void> rejectRequest(String requestId) async {}
  @override
  Future<int> revokeMembers({required String channelId, required List<String> revokeDeviceIds}) async => 1;
  @override
  Future<PairingSessionModel> createPairingSession(String channelId) async => throw UnimplementedError();
  @override
  Future<int?> provisionLatestChannelKey({required String channelId, required String ownerPublicKeyBase64}) async => null;
  @override
  Future<void> renameDevice(String deviceName) async {}
}

class _FakeChannelKeyStore implements ChannelKeyStore {
  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async {
    return base64Encode(List.filled(32, 1));
  }

  @override
  Future<void> saveChannelKey({required String channelId, required int epoch, required String channelKeyBase64}) async {}
  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async => throw UnimplementedError();
  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async => null;
  @override
  Future<List<int>> listProvisionedEpochs(String channelId) async => [1];
  @override
  Future<void> purgeChannelKeys(String channelId) async {}
}

Future<void> _pumpSettingsPage(
  WidgetTester tester,
  WhitelistRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<WhitelistRepository>.value(value: repository),
          RepositoryProvider<ChannelRepository>.value(value: _FakeChannelRepository()),
          RepositoryProvider<ChannelKeyStore>.value(value: _FakeChannelKeyStore()),
        ],
        child: const WhitelistSettingsPage(
          channelId: 'test_channel',
          channelName: 'Kênh thử nghiệm',
        ),
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
