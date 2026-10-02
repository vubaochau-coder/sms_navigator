import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/errors/app_exceptions.dart';

/// Lỗi phát sinh khi render hoặc lưu ảnh mã QR về thư viện máy.
class QrImageExportException extends AppException {
  const QrImageExportException(super.message, {this.accessDenied = false});

  /// true khi bị từ chối quyền truy cập thư viện ảnh.
  final bool accessDenied;
}

/// Service xuất ảnh mã QR: render PNG nền trắng (đảm bảo quét được kể cả khi
/// thiết bị xem ảnh đang bật Dark Mode) rồi lưu vào thư viện ảnh của thiết bị.
abstract class QrImageExportService {
  /// Render payload QR thành ảnh PNG nền trắng kèm viền (quiet zone).
  Future<Uint8List> renderQrPng({
    required String data,
    required int size,
    int quietZone = 24,
  });

  /// Lưu ảnh PNG vào thư viện máy. Ném [QrImageExportException] khi thất bại.
  Future<void> saveToGallery(Uint8List bytes, {required String fileName});
}

class QrImageExportServiceImpl implements QrImageExportService {
  const QrImageExportServiceImpl();

  static const Color _backgroundColor = Color(0xFFFFFFFF);
  static const Color _foregroundColor = Color(0xFF000000);

  @override
  Future<Uint8List> renderQrPng({
    required String data,
    required int size,
    int quietZone = 24,
  }) async {
    final total = size + quietZone * 2;
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: _foregroundColor,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: _foregroundColor,
      ),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, total.toDouble(), total.toDouble()),
      Paint()..color = _backgroundColor,
    );
    canvas.translate(quietZone.toDouble(), quietZone.toDouble());
    painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
    final picture = recorder.endRecording();

    ui.Image? image;
    try {
      image = await picture.toImage(total, total);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const QrImageExportException('Không tạo được dữ liệu ảnh mã QR.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      picture.dispose();
      image?.dispose();
    }
  }

  @override
  Future<void> saveToGallery(Uint8List bytes, {required String fileName}) async {
    try {
      await Gal.putImageBytes(bytes, name: fileName);
    } on GalException catch (e) {
      switch (e.type) {
        case GalExceptionType.accessDenied:
          throw const QrImageExportException(
            'Chưa được cấp quyền lưu ảnh vào thư viện.',
            accessDenied: true,
          );
        case GalExceptionType.notEnoughSpace:
          throw const QrImageExportException(
            'Bộ nhớ máy không đủ để lưu ảnh.',
          );
        case GalExceptionType.notSupportedFormat:
        case GalExceptionType.unexpected:
          throw const QrImageExportException('Không thể lưu ảnh vào thư viện.');
      }
    }
  }
}
