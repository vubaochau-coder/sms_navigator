import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/dimens.dart';
import '../../../receiver/presentation/pages/receiver_dashboard_page.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_event.dart';
import '../bloc/pairing_state.dart';

class PairingReceiverPage extends StatefulWidget {
  const PairingReceiverPage({super.key});

  @override
  State<PairingReceiverPage> createState() => _PairingReceiverPageState();
}

class _PairingReceiverPageState extends State<PairingReceiverPage> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
  );

  /// Cờ chống quét lặp lại nhiều lần trong khi đang xử lý một mã.
  bool _isProcessing = false;

  /// Lưu lỗi đã hiển thị để tránh SnackBar lặp lại khi state đổi
  /// do các sự kiện khác của bloc (errorMessage vẫn giữ nguyên giữa các tick).
  String? _shownError;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) continue;
      _isProcessing = true;
      _shownError = null;
      if (mounted) {
        context.read<PairingBloc>().add(PairingSubmitReceiverQrEvent(rawValue));
      }
      return;
    }
  }

  void _onPairingStateChanged(BuildContext context, PairingState state) {
    if (state.isSuccess && _isProcessing) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ghép đôi thành công!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReceiverDashboardPage()),
      );
      return;
    }

    final error = state.errorMessage;
    if (error != null && _shownError != error) {
      _shownError = error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<PairingBloc, PairingState>(
        listener: _onPairingStateChanged,
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(controller: _controller, onDetect: _onDetect),
              const _ViewfinderOverlay(),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScannerTopBar(onBack: () => Navigator.pop(context)),
                  _ScannerControls(controller: _controller),
                ],
              ),
            ],
          );
        },
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
            const Expanded(
              child: Text(
                'Quét Mã Ghép Đôi',
                style: TextStyle(
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
  const _ScannerControls({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Căn chỉnh mã QR trên Thiết Bị Gửi vào giữa khung ngắm',
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
