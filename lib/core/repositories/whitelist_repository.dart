import '../models/channel_detail_model.dart';
import '../models/whitelist_config_model.dart';

abstract class WhitelistRepository {
  /// Đọc cấu hình white-list của channel từ native cache.
  Future<WhitelistConfigModel> getWhitelist(String channelId);

  /// Lưu cấu hình white-list (Server-first per v2.2):
  /// Mã hóa E2EE -> PUT server -> nếu thành công -> ghi native cache.
  Future<bool> saveWhitelist({
    required String channelId,
    required WhitelistConfigModel config,
    required int keyEpoch,
    required String channelKeyBase64,
  });

  /// Đồng bộ whitelist từ server (blob) xuống native cache.
  Future<WhitelistConfigModel?> syncWhitelistFromServer({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    required ChannelWhitelistBlobModel blob,
  });

  /// Đọc nhật ký tiếp nhận SMS từ native (30 entry gần nhất, toàn thiết bị).
  Future<List<Map<String, dynamic>>> getRecentLogs();
}
