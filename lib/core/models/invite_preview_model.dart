import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Dữ liệu xem trước kênh từ QR invite trước khi gửi yêu cầu tham gia (API spec §4.6).
class InvitePreviewModel extends Equatable {
  final String sessionId;
  final String channelId;
  final String channelName;
  final String ownerDeviceName;
  final DateTime expiresAt;

  const InvitePreviewModel({
    required this.sessionId,
    required this.channelId,
    required this.channelName,
    required this.ownerDeviceName,
    required this.expiresAt,
  });

  factory InvitePreviewModel.fromMap(Map<String, dynamic> map) {
    final expiresRaw = DataConverter.cvToString(map['expires_at'], '')!;
    final parsedExpires = DateTime.tryParse(expiresRaw)?.toLocal() ?? DateTime.now();

    return InvitePreviewModel(
      sessionId: DataConverter.cvToString(map['session_id'], '')!,
      channelId: DataConverter.cvToString(map['channel_id'], '')!,
      channelName: DataConverter.cvToString(map['channel_name'], '')!,
      ownerDeviceName: DataConverter.cvToString(map['owner_device_name'], '')!,
      expiresAt: parsedExpires,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        channelId,
        channelName,
        ownerDeviceName,
        expiresAt,
      ];
}
