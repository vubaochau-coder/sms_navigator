import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/models/pairing_session_model.dart';
import '../../core/utils/toast_utils.dart';
import 'models/scan_qr_result.dart';
import 'views/scanner_controls.dart';
import 'views/scanner_error_view.dart';
import 'views/scanner_top_bar.dart';
import 'views/scanner_viewfinder_overlay.dart';

export 'models/scan_qr_result.dart';
export 'views/scanner_controls.dart';
export 'views/scanner_error_view.dart';
export 'views/scanner_top_bar.dart';
export 'views/scanner_viewfinder_overlay.dart';

/// Màn hình quét QR dùng chung dạng Picker:
/// - Mở camera, xử lý quyền máy ảnh và mở cài đặt khi bị từ chối;
/// - Quét qua camera hoặc chọn ảnh từ thư viện;
/// - Tự động validate định dạng QR của app (hoặc theo custom validator);
/// - Trả về `Future<ScanQrResult?>` để nơi gọi tự xử lý kết quả.
class QrScanPage extends StatefulWidget {
  const QrScanPage({
    super.key,
    this.validator,
    MobileScannerController? controller,
    ImagePicker? imagePicker,
  }) : _controllerOverride = controller,
       _imagePickerOverride = imagePicker;

  final bool Function(String raw)? validator;
  final MobileScannerController? _controllerOverride;
  final ImagePicker? _imagePickerOverride;

  /// Validator mặc định cho định dạng QR của ứng dụng (lời mời tham gia kênh).
  static bool defaultValidator(String raw) {
    return InvitePayload.tryParse(raw) != null;
  }

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  late final MobileScannerController _controller =
      widget._controllerOverride ??
      MobileScannerController(
        facing: CameraFacing.back,
        detectionSpeed: DetectionSpeed.normal,
      );
  late final ImagePicker _imagePicker =
      widget._imagePickerOverride ?? ImagePicker();

  /// Cờ chống quét lặp lại nhiều lần trong khi đang xử lý một mã.
  bool _isProcessing = false;
  bool _isPickingImage = false;
  Timer? _resumeTimer;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) continue;
      _handleRaw(rawValue);
      return;
    }
  }

  Future<void> _pickAndScanFromGallery() async {
    if (_isProcessing || _isPickingImage) return;
    _isPickingImage = true;
    try {
      await _stopCameraSafely();
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final capture = await _controller.analyzeImage(picked.path);
      final rawValue = capture?.barcodes.firstOrNull?.rawValue;
      if (rawValue == null || rawValue.isEmpty) {
        if (mounted) ToastUtils.showError(context.l10n.scannerNoQrFound);
        return;
      }
      _handleRaw(rawValue);
    } catch (_) {
      if (mounted) ToastUtils.showError(context.l10n.scannerNoQrFound);
    } finally {
      _isPickingImage = false;
      await _startCameraSafely();
    }
  }

  void _handleRaw(String rawValue) {
    _isProcessing = true;
    final isValid = (widget.validator ?? QrScanPage.defaultValidator)(rawValue);
    if (!isValid) {
      ToastUtils.showError(context.l10n.scannerUnsupportedQr);
      _scheduleResume();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop(ScanQrResult(rawValue: rawValue));
    }
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  Future<void> _stopCameraSafely() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _startCameraSafely() async {
    try {
      await _controller.start();
    } catch (_) {}
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    if (widget._controllerOverride == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => ScannerErrorView(error: error),
          ),
          const ScannerViewfinderOverlay(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScannerTopBar(onBack: () => Navigator.pop(context)),
              ScannerControls(
                controller: _controller,
                onPickFromGallery: _pickAndScanFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

