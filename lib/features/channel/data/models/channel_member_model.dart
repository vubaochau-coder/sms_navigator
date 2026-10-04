import 'package:equatable/equatable.dart';

import '../../../../core/utils/data_converter.dart';

/// Một thành viên trong `GET /api/v2/channels/members`.
class ChannelMemberModel extends Equatable {
  final String deviceId;
  final String deviceName;
  final String publicKey;
  final String status;
  final int joinedEpoch;
  final int provisionedEpoch;
  final String joinedAt;

  const ChannelMemberModel({
    required this.deviceId,
    required this.deviceName,
    this.publicKey = '',
    this.status = 'ACTIVE',
    this.joinedEpoch = 1,
    this.provisionedEpoch = 1,
    this.joinedAt = '',
  });

  bool get isActive => status == 'ACTIVE';

  factory ChannelMemberModel.fromMap(Map<String, dynamic> map) {
    return ChannelMemberModel(
      deviceId: DataConverter.cvToString(map['device_id'], '')!,
      deviceName: DataConverter.cvToString(map['device_name'], '')!,
      publicKey: DataConverter.cvToString(map['public_key'], '')!,
      status: DataConverter.cvToString(map['status'], 'ACTIVE')!,
      joinedEpoch: DataConverter.cvToInt(map['joined_epoch'], 1)!,
      provisionedEpoch: DataConverter.cvToInt(map['provisioned_epoch'], 1)!,
      joinedAt: DataConverter.cvToString(map['joined_at'], '')!,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    publicKey,
    status,
    joinedEpoch,
    provisionedEpoch,
    joinedAt,
  ];
}
