import 'package:equatable/equatable.dart';

import '../../../core/models/channel_detail_model.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/models/whitelist_config_model.dart';

/// Trạng thái màn chi tiết kênh của Owner: members + hàng đợi duyệt (2.3, 4.1–4.4). Badge = pendingCount.
class ChannelDetailState extends Equatable {
  final String channelId;
  final ChannelDetailModel? detail;
  final List<ChannelMemberModel> members;
  final List<PairingRequestModel> pendingRequests;

  /// White-list đã giải mã (chỉ xem); null = chưa cấu hình / không đọc được.
  final WhitelistConfigModel? whitelist;
  final bool isLoading;
  final bool isMutating;

  /// Đã rời / giải tán kênh — màn chi tiết tự đóng.
  final bool isClosed;

  /// Device ID của máy đang xem — đánh dấu "(bạn)" trong danh sách thành viên.
  final String? selfDeviceId;

  const ChannelDetailState({
    required this.channelId,
    this.detail,
    this.members = const [],
    this.pendingRequests = const [],
    this.whitelist,
    this.isLoading = false,
    this.isMutating = false,
    this.isClosed = false,
    this.selfDeviceId,
  });

  int get pendingCount => pendingRequests.length;
  bool get isOwner => detail?.isOwner ?? false;

  ChannelDetailState copyWith({
    String? channelId,
    ChannelDetailModel? detail,
    List<ChannelMemberModel>? members,
    List<PairingRequestModel>? pendingRequests,
    WhitelistConfigModel? whitelist,
    bool clearWhitelist = false,
    bool? isLoading,
    bool? isMutating,
    bool? isClosed,
    String? selfDeviceId,
  }) {
    return ChannelDetailState(
      channelId: channelId ?? this.channelId,
      detail: detail ?? this.detail,
      members: members ?? this.members,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      whitelist: clearWhitelist ? null : (whitelist ?? this.whitelist),
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      isClosed: isClosed ?? this.isClosed,
      selfDeviceId: selfDeviceId ?? this.selfDeviceId,
    );
  }

  @override
  List<Object?> get props => [
    channelId,
    detail,
    members,
    pendingRequests,
    whitelist,
    isLoading,
    isMutating,
    isClosed,
    selfDeviceId,
  ];
}

// Backward-compatibility aliases
typedef ApprovalState = ChannelDetailState;
