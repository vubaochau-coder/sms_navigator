import 'package:equatable/equatable.dart';

import '../../../../core/utils/data_converter.dart';
import 'channel_model.dart';

/// Chi tiết 1 kênh + trạng thái của caller — `GET /api/v2/channels/detail`.
class ChannelDetailModel extends Equatable {
  final String channelId;
  final String name;
  final String ownerDeviceId;
  final String ownerDeviceName;
  final String ownerPublicKey;
  final int currentEpoch;
  final int membershipVersion;
  final int memberCount;
  final String status;
  final String createdAt;
  final ChannelRole myRole;
  final String myStatus;
  final int myJoinedEpoch;
  final int myProvisionedEpoch;

  const ChannelDetailModel({
    required this.channelId,
    required this.name,
    this.ownerDeviceId = '',
    this.ownerDeviceName = '',
    this.ownerPublicKey = '',
    this.currentEpoch = 1,
    this.membershipVersion = 1,
    this.memberCount = 1,
    this.status = 'ACTIVE',
    this.createdAt = '',
    this.myRole = ChannelRole.member,
    this.myStatus = 'ACTIVE',
    this.myJoinedEpoch = 1,
    this.myProvisionedEpoch = 1,
  });

  bool get isOwner => myRole == ChannelRole.owner;

  factory ChannelDetailModel.fromMap(Map<String, dynamic> map) {
    final channel = DataConverter.cvToMap<String, dynamic>(map['channel']);
    return ChannelDetailModel(
      channelId: DataConverter.cvToString(channel?['channel_id'], '')!,
      name: DataConverter.cvToString(channel?['name'], '')!,
      ownerDeviceId: DataConverter.cvToString(channel?['owner_device_id'], '')!,
      ownerDeviceName: DataConverter.cvToString(map['owner_device_name'], '')!,
      ownerPublicKey: DataConverter.cvToString(map['owner_public_key'], '')!,
      currentEpoch: DataConverter.cvToInt(channel?['current_epoch'], 1)!,
      membershipVersion:
          DataConverter.cvToInt(channel?['membership_version'], 1)!,
      memberCount: DataConverter.cvToInt(channel?['member_count'], 0)!,
      status: DataConverter.cvToString(channel?['status'], 'ACTIVE')!,
      createdAt: DataConverter.cvToString(channel?['created_at'], '')!,
      myRole: channelRoleFromRaw(DataConverter.cvToString(map['my_role'])),
      myStatus: DataConverter.cvToString(map['my_status'], 'ACTIVE')!,
      myJoinedEpoch: DataConverter.cvToInt(map['my_joined_epoch'], 1)!,
      myProvisionedEpoch:
          DataConverter.cvToInt(map['my_provisioned_epoch'], 1)!,
    );
  }

  @override
  List<Object?> get props => [
    channelId,
    name,
    ownerDeviceId,
    ownerDeviceName,
    ownerPublicKey,
    currentEpoch,
    membershipVersion,
    memberCount,
    status,
    createdAt,
    myRole,
    myStatus,
    myJoinedEpoch,
    myProvisionedEpoch,
  ];
}
