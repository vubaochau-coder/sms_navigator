import 'package:equatable/equatable.dart';

import '../../../../core/utils/data_converter.dart';
import '../../../../core/utils/date_time_utils.dart';

/// Đại diện cho thiết bị đã ghép nối (dành cho cả danh sách Receiver của Sender và Sender của Receiver)
class PairedDeviceItem extends Equatable {
  const PairedDeviceItem({
    required this.pairId,
    required this.deviceId,
    this.deviceName,
    this.platform,
    this.pairedAt,
    this.lastActiveAt,
    this.isSender = false,
  });

  final String pairId;

  /// Đối với Sender nhìn sang: deviceId của Receiver.
  /// Đối với Receiver nhìn sang: deviceId của Sender.
  final String deviceId;

  final String? deviceName;
  final String? platform;

  /// Thời điểm ghép đôi (ISO 8601 từ server).
  final DateTime? pairedAt;

  /// Thời điểm hoạt động gần nhất trên server (ISO 8601 từ server).
  final DateTime? lastActiveAt;

  /// true nếu đây là bản ghi máy gửi (khi Receiver xem)
  final bool isSender;

  String get displayName {
    if (deviceName != null && deviceName!.trim().isNotEmpty) {
      return deviceName!.trim();
    }
    return deviceId.isNotEmpty
        ? deviceId
        : (isSender ? 'Thiết bị gửi' : 'Thiết bị nhận');
  }

  String get formattedPairedAt => DateTimeUtils.formatDateTime(pairedAt);

  String get formattedLastActiveAt => lastActiveAt != null
      ? DateTimeUtils.formatDateTime(lastActiveAt)
      : 'Chưa có hoạt động';

  PairedDeviceItem copyWith({
    String? pairId,
    String? deviceId,
    String? deviceName,
    String? platform,
    DateTime? pairedAt,
    DateTime? lastActiveAt,
    bool? isSender,
  }) {
    return PairedDeviceItem(
      pairId: pairId ?? this.pairId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      pairedAt: pairedAt ?? this.pairedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isSender: isSender ?? this.isSender,
    );
  }

  factory PairedDeviceItem.fromReceiverJson(Map<String, dynamic> json) {
    return PairedDeviceItem(
      pairId: DataConverter.cvToString(json['pair_id'], '')!,
      deviceId: DataConverter.cvToString(json['receiver_device_id'], '')!,
      deviceName: DataConverter.cvToString(json['device_name']),
      platform: DataConverter.cvToString(json['platform']),
      pairedAt: DataConverter.cvToDateTime(json['paired_at']),
      lastActiveAt: DataConverter.cvToDateTime(json['last_active_at']),
      isSender: false,
    );
  }

  factory PairedDeviceItem.fromSenderJson(Map<String, dynamic> json) {
    return PairedDeviceItem(
      pairId: DataConverter.cvToString(json['pair_id'], '')!,
      deviceId: DataConverter.cvToString(json['sender_device_id'], '')!,
      deviceName: DataConverter.cvToString(json['device_name']),
      platform: DataConverter.cvToString(json['platform']),
      pairedAt: DataConverter.cvToDateTime(json['paired_at']),
      lastActiveAt: DataConverter.cvToDateTime(json['last_active_at']),
      isSender: true,
    );
  }

  @override
  List<Object?> get props => [
    pairId,
    deviceId,
    deviceName,
    platform,
    pairedAt,
    lastActiveAt,
    isSender,
  ];
}
