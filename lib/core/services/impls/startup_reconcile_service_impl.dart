import '../../usecases/sync_channel_keys_use_case.dart';
import '../../utils/app_logger.dart';
import '../channel_key_store.dart';
import '../device_storage_service.dart';
import '../startup_reconcile_service.dart';

/// Đồng bộ trạng thái khi mở app (SRD 7.3): bảo đảm có identity, rồi lấy key
/// của **mọi** epoch còn thiếu bằng một request (`SyncChannelKeysUseCase`).
///
/// - Không đăng ký thiết bị ở đây: máy chưa có token thì Splash là nơi duy
///   nhất quyết định (thiết lập mới / khôi phục — FLOW_AUDIT S1).
/// - Single-flight + [minInterval]: Splash, màn chính và tab Kênh đều gọi khi
///   khởi động; các lần gọi sát nhau dùng chung kết quả thay vì chạy lại
///   (FLOW_AUDIT P1). Lần chạy lỗi không tính → lần gọi sau thử lại ngay.
class StartupReconcileServiceImpl implements StartupReconcileService {
  StartupReconcileServiceImpl({
    required DeviceStorageService deviceStorage,
    required ChannelKeyStore keyStore,
    required SyncChannelKeysUseCase syncChannelKeys,
    this.minInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _deviceStorage = deviceStorage,
       _keyStore = keyStore,
       _syncChannelKeys = syncChannelKeys,
       _now = clock ?? DateTime.now;

  final DeviceStorageService _deviceStorage;
  final ChannelKeyStore _keyStore;
  final SyncChannelKeysUseCase _syncChannelKeys;
  final Duration minInterval;
  final DateTime Function() _now;

  Future<void>? _inFlight;
  DateTime? _lastSuccessAt;

  @override
  Future<void> reconcile() {
    final running = _inFlight;
    if (running != null) return running;
    final last = _lastSuccessAt;
    if (last != null && _now().difference(last) < minInterval) return Future.value();

    final run = _run().whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<void> _run() async {
    try {
      await _keyStore.getOrCreateIdentityKeyPair();
      final token = await _deviceStorage.getDeviceToken();
      if (token == null || token.isEmpty) return;

      await _syncChannelKeys();
      _lastSuccessAt = _now();
    } catch (error, stack) {
      AppLogger.w('StartupReconcile', 'Startup reconcile skipped or encountered error', error, stack);
    }
  }
}
