import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../scanner/presentation/pages/qr_scan_page.dart';
import '../../../scanner/presentation/scanning/qr_scan_handler_registry.dart';
import '../scanning/join_channel_handler.dart';

/// Màn quét QR chuyên cho luồng tham gia kênh: scanner trung tính + registry
/// chỉ chứa [JoinChannelHandler] (GĐ0 — thêm handler mới không sửa scanner).
class JoinQrScanPage extends StatelessWidget {
  const JoinQrScanPage({
    super.key,
    MobileScannerController? controller,
    ImagePicker? imagePicker,
  }) : _controllerOverride = controller,
       _imagePickerOverride = imagePicker;

  final MobileScannerController? _controllerOverride;
  final ImagePicker? _imagePickerOverride;

  @override
  Widget build(BuildContext context) {
    return QrScanPage(
      registry: QrScanHandlerRegistry(handlers: [JoinChannelHandler()]),
      controller: _controllerOverride,
      imagePicker: _imagePickerOverride,
    );
  }
}
