import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/extensions/context_extensions.dart';

/// Hiển thị thông báo khi quyền máy ảnh bị từ chối hoặc máy ảnh không thể khởi động.
class ScannerErrorView extends StatelessWidget {
  const ScannerErrorView({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
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
  }
}
