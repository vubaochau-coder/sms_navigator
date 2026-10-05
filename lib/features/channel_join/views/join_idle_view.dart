import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// View hiển thị khi chưa gửi yêu cầu tham gia kênh nào.
class JoinIdleView extends StatelessWidget {
  const JoinIdleView({super.key, required this.onRescan});

  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(l10n.joinIdleEmptyMessage),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRescan,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.joinReenterInviteAction),
          ),
        ],
      ),
    );
  }
}
