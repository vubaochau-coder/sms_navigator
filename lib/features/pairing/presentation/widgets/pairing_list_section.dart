import 'package:flutter/material.dart';

/// Widget bao bọc nội dung danh sách của từng Tab trong PairingHub,
/// hỗ trợ hiển thị thông báo đầu mục và AutomaticKeepAliveClientMixin để giữ nguyên state khi đổi Tab.
class PairingListSection extends StatefulWidget {
  const PairingListSection({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  State<PairingListSection> createState() => _PairingListSectionState();
}

class _PairingListSectionState extends State<PairingListSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Icon(
                Icons.priority_high_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
