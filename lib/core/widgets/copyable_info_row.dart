import 'package:flutter/material.dart';

import '../utils/ui_utils.dart';

/// Dòng hiển thị nhãn và giá trị có nút copy nhanh tiện dụng
class CopyableInfoRow extends StatelessWidget {
  const CopyableInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.copySuccessMessage,
  });

  final String label;
  final String value;
  final String? copySuccessMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Sao chép',
            onPressed: () => UiUtils.copyToClipboard(
              value,
              successMessage: copySuccessMessage ?? 'Đã sao chép $label',
            ),
          ),
        ],
      ),
    );
  }
}
