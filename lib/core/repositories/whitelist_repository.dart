import '../models/whitelist_config_model.dart';

abstract class WhitelistRepository {
  /// Đọc cấu hình white-list hiện tại từ native.
  Future<WhitelistConfigModel> getWhitelist();

  /// Lưu toàn bộ cấu hình white-list xuống native.
  Future<bool> saveWhitelist(WhitelistConfigModel config);
}
