import 'package:equatable/equatable.dart';

import '../../../core/models/activity_item.dart';

/// Bộ lọc của tab Hoạt động.
enum ActivityFilter { all, relay, channels }

class ActivityState extends Equatable {
  const ActivityState({
    this.items = const [],
    this.filter = ActivityFilter.all,
    this.isLoading = false,
    this.showSkeleton = false,
    this.hasLoaded = false,
  });

  final List<ActivityItem> items;
  final ActivityFilter filter;
  final bool isLoading;

  /// Đang tải lại theo yêu cầu người dùng → hiện shimmer thay cho danh sách.
  final bool showSkeleton;

  /// Đã tải xong ít nhất một lần (phân biệt "đang tải lần đầu" với "trống").
  final bool hasLoaded;

  List<ActivityItem> get visibleItems => switch (filter) {
    ActivityFilter.all => items,
    ActivityFilter.relay => items.where((item) => item is RelayActivityItem || item is RelaySmsActivityItem).toList(),
    ActivityFilter.channels => items.whereType<ChannelActivityItem>().toList(),
  };

  ActivityState copyWith({
    List<ActivityItem>? items,
    ActivityFilter? filter,
    bool? isLoading,
    bool? showSkeleton,
    bool? hasLoaded,
  }) {
    return ActivityState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      showSkeleton: showSkeleton ?? this.showSkeleton,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  @override
  List<Object?> get props => [items, filter, isLoading, showSkeleton, hasLoaded];
}
