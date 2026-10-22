import 'package:equatable/equatable.dart';

import '../enums/channel_role.dart';

export '../enums/channel_role.dart';
import '../utils/data_converter.dart';
import 'channel_detail_model.dart';
import 'whitelist_config_model.dart';

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

  /// Blob white-list E2EE từ `GET /channels` (null: chưa cấu hình / server cũ).
  final ChannelWhitelistBlobModel? whitelistBlob;

  /// White-list đã giải mã để hiện pill trên danh sách — do repository gắn vào.
  final WhitelistConfigModel? whitelist;

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
    this.whitelistBlob,
    this.whitelist,
  });

  bool get isOwner => role == ChannelRole.owner;

  ChannelModel copyWith({WhitelistConfigModel? whitelist}) {
    return ChannelModel(
      channelId: channelId,
      name: name,
      role: role,
      status: status,
      currentEpoch: currentEpoch,
      membershipVersion: membershipVersion,
      memberCount: memberCount,
      myJoinedEpoch: myJoinedEpoch,
      ownerDeviceName: ownerDeviceName,
      whitelistBlob: whitelistBlob,
      whitelist: whitelist ?? this.whitelist,
    );
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map) {
    final rawWhitelist = map['whitelist'] is Map
        ? Map<String, dynamic>.from(map['whitelist'] as Map)
        : null;
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
      whitelistBlob: rawWhitelist != null ? ChannelWhitelistBlobModel.fromMap(rawWhitelist) : null,
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
    whitelistBlob,
    whitelist,
  ];
}
