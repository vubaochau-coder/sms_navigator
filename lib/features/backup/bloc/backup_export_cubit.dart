import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/crypto/backup_crypto.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/repositories/backup_repository.dart';
import '../../../core/ui/dialog_utils.dart';
import '../../../core/ui/toast_utils.dart';
import '../backup_messages.dart';

class BackupExportState extends Equatable {
  const BackupExportState({this.isExporting = false, this.lastBackup, this.failure});

  final bool isExporting;
  final BackupSummary? lastBackup;
  final BackupFailure? failure;

  @override
  List<Object?> get props => [isExporting, lastBackup, failure];
}

/// Tạo bản sao lưu `.smsnav` (BACKLOG 1.1). Loading + toast qua
/// DialogUtils/ToastUtils theo quy ước của dự án.
class BackupExportCubit extends Cubit<BackupExportState> {
  BackupExportCubit({required BackupRepository repository})
    : _repository = repository,
      super(const BackupExportState());

  final BackupRepository _repository;

  Future<bool> export(String passphrase) async {
    if (state.isExporting) return false;
    emit(BackupExportState(isExporting: true, lastBackup: state.lastBackup));
    DialogUtils.showLoading(message: AppL10n.current.backupExporting);
    try {
      final summary = await _repository.exportToFile(passphrase: passphrase);
      emit(BackupExportState(lastBackup: summary));
      ToastUtils.showSuccess(AppL10n.current.backupExportSuccess(summary.fileName ?? ''));
      return true;
    } on BackupException catch (e) {
      emit(BackupExportState(lastBackup: state.lastBackup, failure: e.failure));
      final message = backupFailureMessage(e.failure);
      if (message != null) ToastUtils.showError(message);
      return false;
    } catch (_) {
      emit(BackupExportState(lastBackup: state.lastBackup, failure: BackupFailure.storage));
      ToastUtils.showError(AppL10n.current.backupErrorStorage);
      return false;
    } finally {
      DialogUtils.closeLoading();
    }
  }
}
