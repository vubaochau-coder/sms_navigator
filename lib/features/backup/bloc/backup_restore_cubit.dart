import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/crypto/backup_crypto.dart';
import '../../../core/repositories/backup_repository.dart';

enum BackupRestoreStatus { idle, picking, fileSelected, restoring, success }

class BackupRestoreState extends Equatable {
  const BackupRestoreState({
    this.status = BackupRestoreStatus.idle,
    this.fileBytes,
    this.failure,
    this.summary,
  });

  final BackupRestoreStatus status;

  /// Nội dung file đã chọn (vẫn đang mã hoá — chưa có bí mật nào lộ ra).
  final Uint8List? fileBytes;
  final BackupFailure? failure;
  final BackupSummary? summary;

  bool get hasFile => fileBytes != null;
  bool get isBusy => status == BackupRestoreStatus.picking || status == BackupRestoreStatus.restoring;

  @override
  List<Object?> get props => [status, fileBytes, failure, summary];
}

/// Khôi phục từ `.smsnav` ở Splash lần đầu (BACKLOG 1.1): chọn file → nhập
/// mật khẩu → ghi danh tính. Lỗi hiển thị ngay trên màn (sai mật khẩu thì
/// cho nhập lại, không phải chọn lại file).
class BackupRestoreCubit extends Cubit<BackupRestoreState> {
  BackupRestoreCubit({required BackupRepository repository})
    : _repository = repository,
      super(const BackupRestoreState());

  final BackupRepository _repository;

  Future<void> pickFile() async {
    if (state.isBusy) return;
    final previous = state.fileBytes;
    emit(BackupRestoreState(status: BackupRestoreStatus.picking, fileBytes: previous));
    try {
      final bytes = await _repository.pickBackupFile();
      if (bytes == null || bytes.isEmpty) {
        // Huỷ chọn → giữ file trước đó (nếu có).
        emit(BackupRestoreState(
          status: previous == null ? BackupRestoreStatus.idle : BackupRestoreStatus.fileSelected,
          fileBytes: previous,
        ));
        return;
      }
      emit(BackupRestoreState(status: BackupRestoreStatus.fileSelected, fileBytes: bytes));
    } on BackupException catch (e) {
      emit(BackupRestoreState(
        status: previous == null ? BackupRestoreStatus.idle : BackupRestoreStatus.fileSelected,
        fileBytes: previous,
        failure: e.failure,
      ));
    }
  }

  Future<void> restore(String passphrase) async {
    final bytes = state.fileBytes;
    if (bytes == null || state.isBusy) return;
    emit(BackupRestoreState(status: BackupRestoreStatus.restoring, fileBytes: bytes));
    try {
      final summary = await _repository.restore(bytes: bytes, passphrase: passphrase);
      emit(BackupRestoreState(status: BackupRestoreStatus.success, summary: summary));
    } on BackupException catch (e) {
      emit(BackupRestoreState(status: BackupRestoreStatus.fileSelected, fileBytes: bytes, failure: e.failure));
    } catch (_) {
      emit(BackupRestoreState(
        status: BackupRestoreStatus.fileSelected,
        fileBytes: bytes,
        failure: BackupFailure.storage,
      ));
    }
  }
}
