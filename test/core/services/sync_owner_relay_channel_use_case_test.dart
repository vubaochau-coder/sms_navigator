import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/native_relay_service.dart';
import 'package:sms_navigator/core/services/sync_owner_relay_channel_use_case.dart';
import 'package:sms_navigator/core/utils/channel_crypto_helper.dart';

class FakeChannelRepository implements ChannelRepository {
  List<ChannelModel> channels = [];

  @override
  Future<List<ChannelModel>> listChannels() async => channels;

  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) async =>
      throw UnimplementedError();

  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) async => [];

  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) async => [];

  @override
  Future<ChannelModel> createChannel(String name) async =>
      throw UnimplementedError();

  @override
  Future<int> approveRequest({
    required String channelId,
    required PairingRequestModel request,
  }) async => 2;

  @override
  Future<void> rejectRequest(String requestId) async {}

  @override
  Future<int> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
  }) async => 2;

  @override
  Future<PairingSessionModel> createPairingSession(String channelId) async =>
      throw UnimplementedError();

  @override
  Future<int?> provisionLatestChannelKey({
    required String channelId,
    required String ownerPublicKeyBase64,
  }) async => null;

  @override
  Future<void> renameDevice(String newName) async {}
}

class FakeChannelKeyStore implements ChannelKeyStore {
  final Map<String, String> keys = {};

  @override
  Future<String?> getChannelKey({
    required String channelId,
    required int epoch,
  }) async => keys['${channelId}_$epoch'];

  @override
  Future<void> saveChannelKey({
    required String channelId,
    required int epoch,
    required String channelKeyBase64,
  }) async {
    keys['${channelId}_$epoch'] = channelKeyBase64;
  }

  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async =>
      throw UnimplementedError();

  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async => null;

  @override
  Future<List<int>> listProvisionedEpochs(String channelId) async => [1];

  @override
  Future<void> purgeChannelKeys(String channelId) async {
    keys.clear();
  }
}

class FakeDeviceStorageService implements DeviceStorageService {
  String? token = 'token-abc';
  String? serverUrl = 'https://sms-navigator-server.onrender.com';

  @override
  Future<String?> getDeviceId() async => 'device-123';
  @override
  Future<void> saveDeviceId(String deviceId) async {}
  @override
  Future<String?> getDeviceName() async => 'My Device';
  @override
  Future<void> saveDeviceName(String deviceName) async {}
  @override
  Future<String?> getDeviceToken() async => token;
  @override
  Future<void> saveDeviceToken(String deviceToken) async => token = deviceToken;
  @override
  Future<void> clearDeviceToken() async => token = null;
  @override
  Future<String?> getServerUrl() async => serverUrl;
  @override
  Future<void> saveServerUrl(String url) async => serverUrl = url;
  @override
  Future<String?> getFcmToken() async => null;
  @override
  Future<void> saveFcmToken(String fcmToken) async {}
  @override
  Future<void> clearAll() async {}
}

class FakeNativeRelayService implements NativeRelayService {
  Map<String, dynamic>? activeConfig;
  bool cleared = false;

  @override
  Future<bool> setActiveRelayChannel({
    required String channelId,
    required String channelName,
    required int keyEpoch,
    required String channelKeyBase64,
    required String deviceToken,
    String? apiBaseUrl,
  }) async {
    activeConfig = {
      'channelId': channelId,
      'channelName': channelName,
      'keyEpoch': keyEpoch,
      'channelKeyBase64': channelKeyBase64,
      'deviceToken': deviceToken,
      'apiBaseUrl': apiBaseUrl,
    };
    cleared = false;
    return true;
  }

  @override
  Future<bool> clearActiveRelayChannel() async {
    cleared = true;
    activeConfig = null;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getRelayConfig() async => {};
  @override
  Future<WhitelistConfigModel> getWhitelist() async => const WhitelistConfigModel();
  @override
  Future<bool> setWhitelist(WhitelistConfigModel config) async => true;
  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async => [];
  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;
  @override
  Future<bool> requestIgnoreBatteryOptimization() async => true;
  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() async => {};
  @override
  Future<String?> getDeviceName() async => 'Test Device';
  @override
  Future<bool> openAutostartSettings() async => true;
}

void main() {
  late FakeChannelRepository channelRepo;
  late FakeChannelKeyStore keyStore;
  late FakeDeviceStorageService deviceStorage;
  late FakeNativeRelayService nativeRelay;
  late SyncOwnerRelayChannelUseCase useCase;

  setUp(() {
    channelRepo = FakeChannelRepository();
    keyStore = FakeChannelKeyStore();
    deviceStorage = FakeDeviceStorageService();
    nativeRelay = FakeNativeRelayService();
    useCase = SyncOwnerRelayChannelUseCase(
      channelRepository: channelRepo,
      keyStore: keyStore,
      deviceStorage: deviceStorage,
      nativeRelayService: nativeRelay,
    );
  });

  test('clears native relay when user owns no active channels', () async {
    channelRepo.channels = [
      const ChannelModel(
        channelId: 'ch-member',
        name: 'Member Channel',
        role: ChannelRole.member,
        status: 'ACTIVE',
      ),
    ];

    final result = await useCase();
    expect(result, isFalse);
    expect(nativeRelay.cleared, isTrue);
    expect(nativeRelay.activeConfig, isNull);
  });

  test('syncs active owner channel to native relay successfully', () async {
    const ownerChannel = ChannelModel(
      channelId: 'ch-owner-1',
      name: 'Owner Channel',
      role: ChannelRole.owner,
      currentEpoch: 2,
      status: 'ACTIVE',
    );
    channelRepo.channels = [ownerChannel];
    keyStore.keys['ch-owner-1_2'] = 'base64key-for-epoch-2';

    final result = await useCase();
    expect(result, isTrue);
    expect(nativeRelay.cleared, isFalse);
    expect(nativeRelay.activeConfig?['channelId'], 'ch-owner-1');
    expect(nativeRelay.activeConfig?['channelName'], 'Owner Channel');
    expect(nativeRelay.activeConfig?['keyEpoch'], 2);
    expect(nativeRelay.activeConfig?['channelKeyBase64'], 'base64key-for-epoch-2');
    expect(nativeRelay.activeConfig?['deviceToken'], 'token-abc');
  });

  test('syncs with expectedEpoch when higher than currentEpoch (rotation)', () async {
    const ownerChannel = ChannelModel(
      channelId: 'ch-owner-1',
      name: 'Owner Channel',
      role: ChannelRole.owner,
      currentEpoch: 1,
      status: 'ACTIVE',
    );
    channelRepo.channels = [ownerChannel];
    keyStore.keys['ch-owner-1_2'] = 'base64key-rotated-epoch-2';

    final result = await useCase(channelId: 'ch-owner-1', expectedEpoch: 2);
    expect(result, isTrue);
    expect(nativeRelay.activeConfig?['keyEpoch'], 2);
    expect(nativeRelay.activeConfig?['channelKeyBase64'], 'base64key-rotated-epoch-2');
  });
}
