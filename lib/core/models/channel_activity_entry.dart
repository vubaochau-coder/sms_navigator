import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';
import 'channel_event.dart';

/// Một sự kiện kênh đã ghi lại cho tab Hoạt động (chỉ metadata, không có key).
class ChannelActivityEntry extends Equatable {
  const ChannelActivityEntry({
    required this.kind,
    required this.at,
    this.channelId,
    this.channelName,
    this.actorName,
    this.reason,
  });

  factory ChannelActivityEntry.fromEvent(ChannelEvent event, DateTime at) {
    return ChannelActivityEntry(
      kind: event.kind,
      at: at,
      channelId: event.channelId,
      channelName: event.channelName,
      actorName: event.actorName,
      reason: event.reason,
    );
  }

  factory ChannelActivityEntry.fromMap(Map<String, dynamic> map) {
    return ChannelActivityEntry(
      kind: ChannelEventKind.values.firstWhere(
        (kind) => kind.name == map['kind'],
        orElse: () => ChannelEventKind.unknown,
      ),
      at: DataConverter.cvToDateTime(map['at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      channelId: DataConverter.cvToString(map['channel_id']),
      channelName: DataConverter.cvToString(map['channel_name']),
      actorName: DataConverter.cvToString(map['actor_name']),
      reason: DataConverter.cvToString(map['reason']),
    );
  }

  final ChannelEventKind kind;
  final DateTime at;
  final String? channelId;
  final String? channelName;
  final String? actorName;
  final String? reason;

  /// `REVOKED` do Owner giải tán kênh (không phải bị thu hồi riêng).
  bool get isArchived => kind == ChannelEventKind.revoked && reason == 'ARCHIVED';

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'at': at.millisecondsSinceEpoch,
    'channel_id': channelId,
    'channel_name': channelName,
    'actor_name': actorName,
    'reason': reason,
  };

  @override
  List<Object?> get props => [kind, at, channelId, channelName, actorName, reason];
}
