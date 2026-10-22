import 'package:equatable/equatable.dart';

import 'channel_activity_entry.dart';
import 'relay_log_entry.dart';

/// Một dòng trên tab Hoạt động: SMS được relay trên máy này, hoặc sự kiện kênh.
sealed class ActivityItem extends Equatable {
  const ActivityItem();

  /// Thời điểm để sắp xếp (null → xếp cuối).
  DateTime? get at;
}

class RelayActivityItem extends ActivityItem {
  const RelayActivityItem(this.entry);

  final RelayLogEntry entry;

  @override
  DateTime? get at => entry.at;

  @override
  List<Object?> get props => [entry];
}

class ChannelActivityItem extends ActivityItem {
  const ChannelActivityItem(this.entry);

  final ChannelActivityEntry entry;

  @override
  DateTime? get at => entry.at;

  @override
  List<Object?> get props => [entry];
}
