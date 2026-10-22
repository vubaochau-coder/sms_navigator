import 'dart:convert';
import '../../errors/app_exceptions.dart';
import '../../models/channel_detail_model.dart';
import '../../models/whitelist_config_model.dart';
import '../../services/channel_api_service.dart';
import '../../services/native_relay_service.dart';
import '../../crypto/channel_crypto_helper.dart';
import '../whitelist_repository.dart';
import '../../l10n/app_l10n.dart';

class WhitelistRepositoryImpl implements WhitelistRepository {
  final NativeRelayService nativeRelayService;
  final ChannelApiService channelApiService;
  final ChannelCryptoHelper cryptoHelper;

  WhitelistRepositoryImpl({
    required this.nativeRelayService,
    required this.channelApiService,
    required this.cryptoHelper,
  });

  @override
  Future<WhitelistConfigModel> getWhitelist(String channelId) async {
    try {
      return await nativeRelayService.getWhitelist(channelId);
    } catch (_) {
      throw ApiException(AppL10n.current.whitelistLoadFailed);
    }
  }

  @override
  Future<bool> saveWhitelist({
    required String channelId,
    required WhitelistConfigModel config,
    required int keyEpoch,
    required String channelKeyBase64,
  }) async {
    // 1. Mã hóa E2EE whitelist blob bằng channel key của epoch hiện tại (v2.2)
    final plaintextJson = jsonEncode(config.toJson());
    final encrypted = await cryptoHelper.encryptMessage(
      plaintext: plaintextJson,
      channelKeyBase64: channelKeyBase64,
      channelId: channelId,
      keyEpoch: keyEpoch,
      sequenceHint: 0,
    );

    // 2. PUT server (Server là nguồn chân lý duy nhất — bắt buộc online)
    await channelApiService.updateChannelWhitelist(
      channelId: channelId,
      keyEpoch: keyEpoch,
      ciphertext: encrypted.ciphertextBase64,
      nonce: encrypted.nonceBase64,
      whitelistVersion: config.version,
    );

    // 3. PUT server thành công -> ghi cache native
    return await nativeRelayService.setWhitelist(channelId, config);
  }

  @override
  Future<WhitelistConfigModel?> decryptWhitelist({
    required String channelId,
    required String channelKeyBase64,
    required ChannelWhitelistBlobModel blob,
  }) async {
    try {
      final decryptedJson = await cryptoHelper.decryptMessage(
        ciphertextBase64: blob.ciphertext,
        nonceBase64: blob.nonce,
        channelKeyBase64: channelKeyBase64,
        channelId: channelId,
        keyEpoch: blob.keyEpoch,
        sequenceHint: 0,
      );
      final decodedMap = jsonDecode(decryptedJson) as Map<String, dynamic>;
      return WhitelistConfigModel.fromJson(decodedMap).copyWith(
        version: blob.whitelistVersion,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WhitelistConfigModel?> syncWhitelistFromServer({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    required ChannelWhitelistBlobModel blob,
  }) async {
    final config = await decryptWhitelist(
      channelId: channelId,
      channelKeyBase64: channelKeyBase64,
      blob: blob,
    );
    if (config == null) return null;
    try {
      await nativeRelayService.setWhitelist(channelId, config);
      return config;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async {
    try {
      return await nativeRelayService.getRecentLogs();
    } catch (_) {
      return const [];
    }
  }
}
