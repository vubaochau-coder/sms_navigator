import 'package:flutter/material.dart';

/// Bọc EmptyStateView trong vùng cuộn được để hỗ trợ pull-to-refresh
/// khi danh sách thiết bị rỗng.
class RefreshableEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshableEmptyState({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: child,
          ),
        ],
      ),
    );
  }
}
