import 'dart:typed_data';

/// Lưu / mở file sao lưu qua trình chọn file của hệ thống (Android SAF).
abstract class BackupFileService {
  /// `true` = đã lưu, `false` = người dùng huỷ.
  Future<bool> saveFile({required String fileName, required Uint8List bytes});

  /// Nội dung file, hoặc `null` nếu người dùng huỷ.
  Future<Uint8List?> openFile();
}
