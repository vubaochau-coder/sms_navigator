import '../models/whitelist_config_model.dart';

abstract class WhitelistRepository {
  /// Đọc cấu hình white-list hiện tại từ native.
  Future<WhitelistConfigModel> getWhitelist();

  /// Lưu toàn bộ cấu hình white-list xuống native.
  Future<bool> saveWhitelist(WhitelistConfigModel config);

  /// Đọc nhật ký tiếp nhận SMS từ native (30 entry gần nhất) — dùng để
  /// truy vết pipeline nhận SMS: SMS đã đi tới gate nào, bị chặn vì sao.
  Future<List<Map<String, dynamic>>> getRecentLogs();
}
