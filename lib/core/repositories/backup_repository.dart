import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Tóm tắt một bản sao lưu — hiển thị cho người dùng, không chứa bí mật.
class BackupSummary extends Equatable {
  const BackupSummary({
    required this.channelCount,
    required this.createdAt,
    this.deviceName,
    this.fileName,
  });

  final String? deviceName;
  final int channelCount;
  final DateTime createdAt;
  final String? fileName;

  @override
  List<Object?> get props => [deviceName, channelCount, createdAt, fileName];
}

/// Lần sao lưu (hoặc khôi phục) gần nhất trên máy này — chỉ metadata, không
/// có bí mật. Dùng cho banner nhắc sao lưu (BACKLOG 1.9).
class BackupRecord extends Equatable {
  const BackupRecord({required this.at, required this.channelIds});

  final DateTime at;
  final Set<String> channelIds;

  Map<String, dynamic> toJson() => {'at': at.toUtc().toIso8601String(), 'channels': channelIds.toList()};

  static BackupRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse('${raw['at']}');
    final channels = raw['channels'];
    if (at == null || channels is! List) return null;
    return BackupRecord(at: at.toLocal(), channelIds: channels.map((e) => '$e').toSet());
  }

  // So theo thời điểm, không theo múi giờ của DateTime.
  @override
  List<Object?> get props => [at.toUtc(), channelIds];
}

/// Sao lưu & khôi phục danh tính + khoá (BACKLOG 1.1).
///
/// Lỗi đều là `BackupException` (xem `BackupFailure`).
abstract class BackupRepository {
  /// Mã hoá toàn bộ danh tính + channel key bằng [passphrase] rồi mở hộp thoại
  /// lưu file. Người dùng huỷ → `BackupFailure.cancelled`.
  Future<BackupSummary> exportToFile({required String passphrase});

  /// Mở trình chọn file; `null` nếu người dùng huỷ.
  Future<Uint8List?> pickBackupFile();

  /// Giải mã + ghi lại danh tính lên máy này. **Chỉ dùng trên bản cài chưa
  /// đăng ký** (Splash lần đầu) — ghi đè identity hiện có.
  Future<BackupSummary> restore({required Uint8List bytes, required String passphrase});

  /// Lần sao lưu / khôi phục thành công gần nhất (null = chưa từng).
  BackupRecord? lastBackupRecord();
}
