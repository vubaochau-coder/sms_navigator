import 'package:equatable/equatable.dart';

import 'channel_activity_entry.dart';
import 'relay_log_entry.dart';
import 'relay_sms_activity.dart';

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

/// Một SMS với kết quả trên mọi kênh (gộp các dòng nhật ký cùng `sms_id`).
class RelaySmsActivityItem extends ActivityItem {
  const RelaySmsActivityItem(this.activity);

  final RelaySmsActivity activity;

  @override
  DateTime? get at => activity.at;

  @override
  List<Object?> get props => [activity];
}

class ChannelActivityItem extends ActivityItem {
  const ChannelActivityItem(this.entry);

  final ChannelActivityEntry entry;

  @override
  DateTime? get at => entry.at;

  @override
  List<Object?> get props => [entry];
}
