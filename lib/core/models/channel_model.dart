import 'package:equatable/equatable.dart';

import '../enums/channel_role.dart';

export '../enums/channel_role.dart';
import '../utils/data_converter.dart';

ChannelRole channelRoleFromRaw(String? raw) =>
    raw == 'OWNER' ? ChannelRole.owner : ChannelRole.member;

/// Một kênh trong danh sách `GET /api/v2/channels`.
class ChannelModel extends Equatable {
  final String channelId;
  final String name;
  final ChannelRole role;
  final String status;
  final int currentEpoch;
  final int membershipVersion;
  final int memberCount;
  final int myJoinedEpoch;
  final String ownerDeviceName;

  const ChannelModel({
    required this.channelId,
    required this.name,
    required this.role,
    this.status = 'ACTIVE',
    this.currentEpoch = 1,
    this.membershipVersion = 1,
    this.memberCount = 1,
    this.myJoinedEpoch = 1,
    this.ownerDeviceName = '',
  });

  bool get isOwner => role == ChannelRole.owner;

  factory ChannelModel.fromMap(Map<String, dynamic> map) {
    return ChannelModel(
      channelId: DataConverter.cvToString(map['channel_id'], '')!,
      name: DataConverter.cvToString(map['name'], '')!,
      role: channelRoleFromRaw(DataConverter.cvToString(map['role'])),
      status: DataConverter.cvToString(map['status'], 'ACTIVE')!,
      currentEpoch: DataConverter.cvToInt(map['current_epoch'], 1)!,
      membershipVersion: DataConverter.cvToInt(map['membership_version'], 1)!,
      memberCount: DataConverter.cvToInt(map['member_count'], 0)!,
      myJoinedEpoch: DataConverter.cvToInt(map['my_joined_epoch'], 1)!,
      ownerDeviceName: DataConverter.cvToString(map['owner_device_name'], '')!,
    );
  }

  @override
  List<Object?> get props => [
    channelId,
    name,
    role,
    status,
    currentEpoch,
    membershipVersion,
    memberCount,
    myJoinedEpoch,
    ownerDeviceName,
  ];
}
