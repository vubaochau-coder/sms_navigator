import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Loại sự kiện kênh mà FCM "chuông" báo về (API spec §7).
enum ChannelEventKind {
  joinRequest,
  approved,
  revoked,
  newMessage,
  memberLeft,
  unknown;

  static ChannelEventKind fromWire(String? kind) => switch (kind) {
    'JOIN_REQUEST' => ChannelEventKind.joinRequest,
    'APPROVED' => ChannelEventKind.approved,
    'REVOKED' => ChannelEventKind.revoked,
    'NEW_MESSAGE' => ChannelEventKind.newMessage,
    'MEMBER_LEFT' => ChannelEventKind.memberLeft,
    _ => ChannelEventKind.unknown,
  };
}

/// Một sự kiện kênh từ FCM data payload hoặc từ việc người dùng chạm vào
/// thông báo. Chỉ là metadata — **không bao giờ** chứa ciphertext/key (I5).
class ChannelEvent extends Equatable {
  const ChannelEvent({
    required this.kind,
    this.channelId,
    this.channelName,
    this.sequenceNumber,
    this.senderDeviceId,
    this.actorName,
    this.reason,
    this.openedFromNotification = false,
  });

  factory ChannelEvent.fromData(Map<String, dynamic> data) {
    String? nonEmpty(Object? value) {
      final text = DataConverter.cvToString(value)?.trim();
      return text == null || text.isEmpty ? null : text;
    }

    return ChannelEvent(
      kind: ChannelEventKind.fromWire(nonEmpty(data['kind'])),
      channelId: nonEmpty(data['channel_id']),
      channelName: nonEmpty(data['channel_name']),
      sequenceNumber: DataConverter.cvToInt(data['sequence_number']),
      senderDeviceId: nonEmpty(data['sender_device_id']),
      actorName: nonEmpty(data['requester_device_name']) ?? nonEmpty(data['device_name']),
      reason: nonEmpty(data['reason']),
    );
  }

  final ChannelEventKind kind;
  final String? channelId;
  final String? channelName;
  final int? sequenceNumber;
  final String? senderDeviceId;

  /// Tên máy liên quan: người xin vào (`JOIN_REQUEST`) / người rời (`MEMBER_LEFT`).
  final String? actorName;

  /// Lý do kèm theo, vd `ARCHIVED` khi `REVOKED` do Owner giải tán kênh.
  final String? reason;

  /// `true` khi sự kiện đến từ thao tác chạm/nút trên thông báo.
  final bool openedFromNotification;

  /// Sự kiện làm thay đổi danh sách tin nhắn mà màn SMS đang hiển thị.
  bool get affectsMessages =>
      kind == ChannelEventKind.newMessage ||
      kind == ChannelEventKind.approved ||
      kind == ChannelEventKind.revoked;

  @override
  List<Object?> get props => [
    kind,
    channelId,
    channelName,
    sequenceNumber,
    senderDeviceId,
    actorName,
    reason,
    openedFromNotification,
  ];
}
