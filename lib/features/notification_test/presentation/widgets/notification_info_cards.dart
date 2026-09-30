import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationHeaderCard extends StatelessWidget {
  const NotificationHeaderCard({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiểm Thử Trực Quan Thông Báo Push',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bấm nút bên dưới để vừa kích hoạt thông báo hệ thống thực tế trên thanh Status bar, vừa xem Mockup UI trực quan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationPermissionWarningCard extends StatelessWidget {
  const NotificationPermissionWarningCard({
    super.key,
    required this.onRequestPermission,
    required this.colorScheme,
  });

  final VoidCallback onRequestPermission;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chưa cấp quyền thông báo. Vui lòng cho phép để xem thông báo nổi trên màn hình.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onRequestPermission,
            child: const Text('Cấp Quyền'),
          ),
        ],
      ),
    );
  }
}

class NotificationSectionTitle extends StatelessWidget {
  const NotificationSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FcmStatusCard extends StatelessWidget {
  const FcmStatusCard({
    super.key,
    required this.fcmToken,
    required this.hasPermission,
    required this.colorScheme,
  });

  final String? fcmToken;
  final bool hasPermission;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Thông Tin FCM Device Token',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fcmToken != null && fcmToken!.isNotEmpty
                ? 'FCM Token: ${fcmToken!.substring(0, fcmToken!.length > 30 ? 30 : fcmToken!.length)}...'
                : 'Chưa lấy được FCM Token (chạy trên giả lập không có Play Services hoặc offline).',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (fcmToken != null && fcmToken!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.copy, size: 12),
                label: const Text('Sao chép toàn bộ Token',
                    style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fcmToken!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã sao chép FCM Token vào bộ nhớ tạm!')),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
