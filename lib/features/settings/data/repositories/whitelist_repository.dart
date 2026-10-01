import '../../../../core/errors/app_exceptions.dart';
import '../../../sender/data/models/whitelist_config_model.dart';
import '../../../sender/data/services/native_relay_service.dart';

abstract class WhitelistRepository {
  /// Đọc cấu hình white-list hiện tại từ native.
  Future<WhitelistConfigModel> getWhitelist();

  /// Lưu toàn bộ cấu hình white-list xuống native.
  Future<bool> saveWhitelist(WhitelistConfigModel config);
}

class WhitelistRepositoryImpl implements WhitelistRepository {
  final NativeRelayService nativeRelayService;

  WhitelistRepositoryImpl({required this.nativeRelayService});

  @override
  Future<WhitelistConfigModel> getWhitelist() async {
    try {
      return await nativeRelayService.getWhitelist();
    } catch (_) {
      throw const ApiException('Không thể đọc cấu hình white-list');
    }
  }

  @override
  Future<bool> saveWhitelist(WhitelistConfigModel config) async {
    try {
      return await nativeRelayService.setWhitelist(config);
    } catch (_) {
      return false;
    }
  }
}
