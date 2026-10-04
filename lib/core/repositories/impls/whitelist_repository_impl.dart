import '../../errors/app_exceptions.dart';
import '../../models/whitelist_config_model.dart';
import '../../services/native_relay_service.dart';
import '../whitelist_repository.dart';

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
