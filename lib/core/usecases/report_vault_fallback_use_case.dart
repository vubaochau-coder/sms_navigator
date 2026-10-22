import '../l10n/app_l10n.dart';
import '../models/vault_fallback_report.dart';
import '../services/crashlytics_service.dart';
import '../services/native_relay_service.dart';
import '../ui/toast_utils.dart';
import '../utils/app_logger.dart';

/// Lỗi non-fatal gửi Crashlytics khi Keystore buộc native lưu dữ liệu thô.
class VaultFallbackError implements Exception {
  const VaultFallbackError(this.report);

  final VaultFallbackReport report;

  @override
  String toString() =>
      'SecureVault fallback ×${report.count} (last at ${report.site}): ${report.error}';
}

/// BACKLOG 2.2 — gọi một lần lúc khởi động: native giữ fail-open (relay không
/// dừng khi Keystore chập chờn) nhưng mọi lần lưu thô đều được báo cáo
/// (Crashlytics non-fatal) và người dùng được cảnh báo.
class ReportVaultFallbackUseCase {
  ReportVaultFallbackUseCase({
    required NativeRelayService nativeRelay,
    required CrashlyticsService crashlytics,
    void Function(String message)? warn,
  }) : _nativeRelay = nativeRelay,
       _crashlytics = crashlytics,
       _warn = warn ?? ((message) => ToastUtils.showWarning(message));

  final NativeRelayService _nativeRelay;
  final CrashlyticsService _crashlytics;
  final void Function(String message) _warn;

  Future<VaultFallbackReport?> call() async {
    final report = await _nativeRelay.takeVaultFallbackReport();
    if (report == null) return null;

    final error = VaultFallbackError(report);
    AppLogger.w('VaultFallback', error.toString());
    await _crashlytics.recordError(error, null, reason: 'secure_vault_fallback');
    _warn(AppL10n.current.vaultFallbackWarning);
    return report;
  }
}
