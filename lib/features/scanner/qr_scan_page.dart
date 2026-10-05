import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/models/pairing_session_model.dart';
import '../../core/utils/toast_utils.dart';
import 'models/scan_qr_result.dart';

export 'models/scan_qr_result.dart';

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

  /// Hàm Future tiện ích để mở màn hình quét QR và nhận kết quả trả về.
  static Future<ScanQrResult?> scan(
    BuildContext context, {
    bool Function(String raw)? validator,
  }) {
    return Navigator.of(context).push<ScanQrResult>(
      MaterialPageRoute(
        builder: (_) => QrScanPage(validator: validator),
      ),
    );
  }

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
            errorBuilder: (context, error) {
              final isPermissionDenied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPermissionDenied
                            ? 'Ứng dụng cần quyền truy cập máy ảnh để quét mã QR'
                            : 'Không thể khởi động máy ảnh: ${error.errorDetails?.message ?? error.errorCode.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isPermissionDenied)
                        FilledButton.icon(
                          onPressed: () => openAppSettings(),
                          icon: const Icon(Icons.settings),
                          label: Text(context.l10n.openAppSettingsAction),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const _ViewfinderOverlay(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScannerTopBar(onBack: () => Navigator.pop(context)),
              _ScannerControls(
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

/// Lớp phủ tối mờ với lỗ cắt vuông ở giữa và viền bo góc phát sáng.
class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  static const double _cutoutSize = 260;
  static const double _cutoutRadius = 24;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cutout = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: _cutoutSize,
            height: _cutoutSize,
          ),
          const Radius.circular(_cutoutRadius),
        );
        return CustomPaint(
          painter: _ViewfinderPainter(rrect: cutout, borderColor: borderColor),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.rrect, required this.borderColor});

  final RRect rrect;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final mask = Path()..addRect(screen);
    final hole = Path()..addRRect(rrect);
    final combined = Path.combine(PathOperation.difference, mask, hole);
    canvas.drawPath(combined, Paint()..color = Colors.black54);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = borderColor.withValues(alpha: 0.35);
    canvas.drawRRect(rrect.deflate(3), glowPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = borderColor;
    canvas.drawRRect(rrect.deflate(3), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.rrect != rrect || oldDelegate.borderColor != borderColor;
  }
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: Dimens.screenPadding,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                context.l10n.scannerTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerControls extends StatelessWidget {
  const _ScannerControls({
    required this.controller,
    required this.onPickFromGallery,
  });

  final MobileScannerController controller;
  final VoidCallback onPickFromGallery;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.scannerAlignGuide,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, _) {
                    final isTorchOn = state.torchState == TorchState.on;
                    return _ScannerControlButton(
                      icon: isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: () => controller.toggleTorch(),
                    );
                  },
                ),
                const SizedBox(width: 40),
                _ScannerControlButton(
                  icon: Icons.photo_library_rounded,
                  onTap: onPickFromGallery,
                ),
                const SizedBox(width: 40),
                _ScannerControlButton(
                  icon: Icons.cameraswitch_rounded,
                  onTap: () => controller.switchCamera(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerControlButton extends StatelessWidget {
  const _ScannerControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: colorScheme.onPrimary, size: 26),
        ),
      ),
    );
  }
}
