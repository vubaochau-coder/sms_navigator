import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../scanner/presentation/pages/qr_scan_page.dart';
import '../../../scanner/presentation/scanning/qr_scan_handler_registry.dart';
import '../scanning/pairing_qr_scan_handler.dart';

/// Màn hình quét QR chuyên cho luồng ghép đôi: đóng gói registry chứa
/// [PairingQrScanHandler]. Thêm loại QR mới sau này không cần sửa scanner.
class PairingQrScanPage extends StatelessWidget {
  const PairingQrScanPage({
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
      registry: QrScanHandlerRegistry(handlers: [PairingQrScanHandler()]),
      controller: _controllerOverride,
      imagePicker: _imagePickerOverride,
    );
  }
}
