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
  ///
  /// Có thể kèm [title] in đậm và [subtitle] mô tả ngay bên dưới, cùng nằm
  /// phía trên mã để toàn bộ phần chữ gom về một vùng đọc duy nhất.
  Future<Uint8List> renderQrPng({
    required String data,
    required int size,
    int quietZone = 24,
    String? title,
    String? subtitle,
  });

  /// Lưu ảnh PNG vào thư viện máy. Ném [QrImageExportException] khi thất bại.
  Future<void> saveToGallery(Uint8List bytes, {required String fileName});
}

class QrImageExportServiceImpl implements QrImageExportService {
  const QrImageExportServiceImpl();

  static const Color _backgroundColor = Color(0xFFFFFFFF);
  static const Color _foregroundColor = Color(0xFF000000);
  static const Color _titleColor = Color(0xFF111827);
  static const Color _subtitleColor = Color(0xFF6B7280);

  static const double _verticalPadding = 28;
  static const double _subtitleGap = 8;
  static const double _qrGap = 44;
  static const double _titleFontSize = 30;
  static const double _subtitleFontSize = 20;

  @override
  Future<Uint8List> renderQrPng({
    required String data,
    required int size,
    int quietZone = 24,
    String? title,
    String? subtitle,
  }) async {
    final qrWidth = size + quietZone * 2;
    final titlePainter = _buildTextPainter(
      title,
      fontSize: _titleFontSize,
      fontWeight: FontWeight.w700,
      color: _titleColor,
      maxWidth: qrWidth.toDouble(),
    );
    final subtitlePainter = _buildTextPainter(
      subtitle,
      fontSize: _subtitleFontSize,
      fontWeight: FontWeight.w400,
      color: _subtitleColor,
      maxWidth: qrWidth.toDouble(),
    );

    final headerTextHeight = (titlePainter?.height ?? 0) +
        (titlePainter != null && subtitlePainter != null
            ? _subtitleGap
            : 0) +
        (subtitlePainter?.height ?? 0);
    final headerHeight =
        headerTextHeight > 0 ? _verticalPadding + headerTextHeight : 0.0;
    final qrTop = headerHeight > 0 ? headerHeight + _qrGap : 0.0;
    final totalWidth = qrWidth;
    final totalHeight = qrTop + qrWidth + _verticalPadding;

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
      Rect.fromLTWH(0, 0, totalWidth.toDouble(), totalHeight.toDouble()),
      Paint()..color = _backgroundColor,
    );

    var textTop = _verticalPadding;
    titlePainter?.paint(
      canvas,
      Offset((totalWidth - titlePainter.width) / 2, textTop),
    );
    textTop += (titlePainter?.height ?? 0) +
        (titlePainter == null ? 0 : _subtitleGap);
    subtitlePainter?.paint(
      canvas,
      Offset((totalWidth - subtitlePainter.width) / 2, textTop),
    );

    canvas.translate(quietZone.toDouble(), qrTop.toDouble());
    painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
    canvas.translate(-quietZone.toDouble(), -qrTop.toDouble());

    final picture = recorder.endRecording();

    ui.Image? image;
    try {
      image = await picture.toImage(totalWidth, totalHeight.round());
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

  TextPainter? _buildTextPainter(
    String? text, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required double maxWidth,
  }) {
    if (text == null || text.isEmpty) return null;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.25,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter;
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
