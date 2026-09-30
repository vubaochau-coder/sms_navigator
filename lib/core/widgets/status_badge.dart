import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Huy hiệu hiển thị trạng thái linh hoạt (Active, Paused, Pending, Error, Success)
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.textColor,
    this.backgroundColor,
  });

  factory StatusBadge.active({String label = 'Đang hoạt động'}) {
    return StatusBadge(
      label: label,
      color: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  factory StatusBadge.paused({String label = 'Đang tạm dừng'}) {
    return StatusBadge(
      label: label,
      color: AppColors.warning,
      icon: Icons.pause_circle_filled_rounded,
    );
  }

  factory StatusBadge.pending({String label = 'Đang chờ'}) {
    return StatusBadge(
      label: label,
      color: Colors.orange,
      icon: Icons.hourglass_top_rounded,
    );
  }

  factory StatusBadge.error({String label = 'Lỗi'}) {
    return StatusBadge(
      label: label,
      color: AppColors.error,
      icon: Icons.error_rounded,
    );
  }

  final String label;
  final Color color;
  final IconData? icon;
  final Color? textColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    final fg = textColor ?? color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
