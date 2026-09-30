import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_time_utils.dart';

/// Đại diện cho thiết bị đã ghép nối (dành cho cả danh sách Receiver của Sender và Sender của Receiver)
class PairedDeviceItem extends Equatable {
  const PairedDeviceItem({
    required this.pairId,
    required this.deviceId,
    required this.isActive,
    this.deviceName,
    this.platform,
    this.pairedAt,
    this.lastRelayedAt,
    this.isSender = false,
  });

  final String pairId;

  /// Đối với Sender nhìn sang: deviceId của Receiver.
  /// Đối với Receiver nhìn sang: deviceId của Sender.
  final String deviceId;

  /// Trạng thái người gửi duy trì gửi OTP (true) hay tạm dừng (false).
  final bool isActive;

  final String? deviceName;
  final String? platform;
  final int? pairedAt;
  final int? lastRelayedAt;

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

  String get formattedPairedAt => DateTimeUtils.formatEpochSeconds(pairedAt);

  String get formattedLastRelayedAt => lastRelayedAt != null
      ? DateTimeUtils.formatEpochSeconds(lastRelayedAt)
      : 'Chưa có lượt gửi';

  PairedDeviceItem copyWith({
    String? pairId,
    String? deviceId,
    bool? isActive,
    String? deviceName,
    String? platform,
    int? pairedAt,
    int? lastRelayedAt,
    bool? isSender,
  }) {
    return PairedDeviceItem(
      pairId: pairId ?? this.pairId,
      deviceId: deviceId ?? this.deviceId,
      isActive: isActive ?? this.isActive,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      pairedAt: pairedAt ?? this.pairedAt,
      lastRelayedAt: lastRelayedAt ?? this.lastRelayedAt,
      isSender: isSender ?? this.isSender,
    );
  }

  factory PairedDeviceItem.fromReceiverJson(Map<String, dynamic> json) {
    return PairedDeviceItem(
      pairId: json['pair_id']?.toString() ?? '',
      deviceId: json['receiver_device_id']?.toString() ?? '',
      isActive: json['is_active'] != false,
      deviceName: json['device_name']?.toString(),
      platform: json['platform']?.toString(),
      pairedAt: (json['paired_at'] is num)
          ? (json['paired_at'] as num).toInt()
          : null,
      lastRelayedAt: (json['last_relayed_at'] is num)
          ? (json['last_relayed_at'] as num).toInt()
          : null,
      isSender: false,
    );
  }

  factory PairedDeviceItem.fromSenderJson(Map<String, dynamic> json) {
    return PairedDeviceItem(
      pairId: json['pair_id']?.toString() ?? '',
      deviceId: json['sender_device_id']?.toString() ?? '',
      isActive: json['is_active'] != false,
      deviceName: json['device_name']?.toString(),
      platform: json['platform']?.toString(),
      pairedAt: (json['paired_at'] is num)
          ? (json['paired_at'] as num).toInt()
          : null,
      lastRelayedAt: (json['last_relayed_at'] is num)
          ? (json['last_relayed_at'] as num).toInt()
          : null,
      isSender: true,
    );
  }

  @override
  List<Object?> get props => [
    pairId,
    deviceId,
    isActive,
    deviceName,
    platform,
    pairedAt,
    lastRelayedAt,
    isSender,
  ];
}
