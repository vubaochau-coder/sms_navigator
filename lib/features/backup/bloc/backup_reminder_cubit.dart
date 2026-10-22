import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/repositories/backup_repository.dart';
import '../../../core/services/local_storage_service.dart';

/// Banner nhắc sao lưu (BACKLOG 1.9): hiện khi máy có kênh mà bản sao lưu /
/// khôi phục gần nhất chưa chứa — chưa từng sao lưu, hoặc vừa tạo / tham gia
/// kênh mới. Gỡ app mà không có bản sao lưu = mất kênh vĩnh viễn. Bản sao lưu
/// cũ vẫn khôi phục được danh tính; key epoch mới tự lấy lại từ envelope, nên
/// chỉ **tập kênh** quyết định việc nhắc, không phải epoch.
class BackupReminderCubit extends Cubit<bool> {
  /// Thiếu [backupRepository] / [localStorage] (vd. widget test) → không bao giờ nhắc.
  BackupReminderCubit({
    BackupRepository? backupRepository,
    LocalStorageService? localStorage,
    DateTime Function()? clock,
  }) : _backupRepository = backupRepository,
       _localStorage = localStorage,
       _now = clock ?? DateTime.now,
       super(false);

  static const Duration snoozeDuration = Duration(days: 3);

  final BackupRepository? _backupRepository;
  final LocalStorageService? _localStorage;
  final DateTime Function() _now;
  Set<String> _channelIds = const {};

  /// Gọi mỗi khi danh sách kênh (của mình + đã tham gia) thay đổi, và khi quay
  /// lại từ màn sao lưu.
  void update(Iterable<String> channelIds) {
    _channelIds = channelIds.toSet();
    _evaluate();
  }

  void recheck() => _evaluate();

  Future<void> snooze() async {
    await _localStorage?.setString(
      StorageKeys.backupReminderSnoozedUntil,
      _now().add(snoozeDuration).toUtc().toIso8601String(),
    );
    emit(false);
  }

  void _evaluate() {
    if (isClosed) return;
    final repository = _backupRepository;
    final storage = _localStorage;
    if (repository == null || storage == null || _channelIds.isEmpty) return emit(false);

    final snoozedUntil = DateTime.tryParse(storage.getString(StorageKeys.backupReminderSnoozedUntil) ?? '');
    if (snoozedUntil != null && _now().isBefore(snoozedUntil)) return emit(false);

    final record = repository.lastBackupRecord();
    emit(record == null || !record.channelIds.containsAll(_channelIds));
  }
}
