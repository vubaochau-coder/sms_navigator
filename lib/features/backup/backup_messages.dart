import '../../core/crypto/backup_crypto.dart';
import '../../core/l10n/app_l10n.dart';

/// Thông điệp tiếng Việt cho từng [BackupFailure]. `null` = không cần báo
/// (người dùng tự huỷ).
String? backupFailureMessage(BackupFailure failure) {
  final l10n = AppL10n.current;
  return switch (failure) {
    BackupFailure.cancelled => null,
    BackupFailure.wrongPassphrase => l10n.backupErrorWrongPassphrase,
    BackupFailure.invalidFile => l10n.backupErrorInvalidFile,
    BackupFailure.unsupportedVersion => l10n.backupErrorUnsupportedVersion,
    BackupFailure.incompleteBackup => l10n.backupErrorIncomplete,
    BackupFailure.notRegistered => l10n.backupErrorNotRegistered,
    BackupFailure.storage => l10n.backupErrorStorage,
  };
}
