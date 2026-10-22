import 'package:equatable/equatable.dart';

import '../../../core/models/activity_item.dart';

/// Bộ lọc của tab Hoạt động.
enum ActivityFilter { all, relay, channels }

class ActivityState extends Equatable {
  const ActivityState({
    this.items = const [],
    this.filter = ActivityFilter.all,
    this.isLoading = false,
    this.hasLoaded = false,
  });

  final List<ActivityItem> items;
  final ActivityFilter filter;
  final bool isLoading;

  /// Đã tải xong ít nhất một lần (phân biệt "đang tải lần đầu" với "trống").
  final bool hasLoaded;

  List<ActivityItem> get visibleItems => switch (filter) {
    ActivityFilter.all => items,
    ActivityFilter.relay => items.whereType<RelayActivityItem>().toList(),
    ActivityFilter.channels => items.whereType<ChannelActivityItem>().toList(),
  };

  ActivityState copyWith({
    List<ActivityItem>? items,
    ActivityFilter? filter,
    bool? isLoading,
    bool? hasLoaded,
  }) {
    return ActivityState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  @override
  List<Object?> get props => [items, filter, isLoading, hasLoaded];
}
