import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/extensions/context_extensions.dart';

/// Bảng điều khiển phía dưới màn hình quét: hướng dẫn, flash, chọn ảnh từ gallery, đổi camera.
class ScannerControls extends StatelessWidget {
  const ScannerControls({
    super.key,
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
                    return ScannerControlButton(
                      icon: isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: () => controller.toggleTorch(),
                    );
                  },
                ),
                const SizedBox(width: 40),
                ScannerControlButton(
                  icon: Icons.photo_library_rounded,
                  onTap: onPickFromGallery,
                ),
                const SizedBox(width: 40),
                ScannerControlButton(
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

/// Nút bấm tròn phong cách scanner.
class ScannerControlButton extends StatelessWidget {
  const ScannerControlButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

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
