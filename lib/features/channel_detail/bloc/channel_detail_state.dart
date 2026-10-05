import 'package:equatable/equatable.dart';

import '../../../core/models/channel_detail_model.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/models/pairing_session_model.dart';

/// Trạng thái màn chi tiết kênh của Owner: members + hàng đợi duyệt + QR
/// invite đang hiệu lực (2.3, 4.1–4.4). Badge = pendingCount.
class ChannelDetailState extends Equatable {
  final String channelId;
  final ChannelDetailModel? detail;
  final List<ChannelMemberModel> members;
  final List<PairingRequestModel> pendingRequests;
  final PairingSessionModel? activeSession;
  final bool isLoading;
  final bool isMutating;

  const ChannelDetailState({
    required this.channelId,
    this.detail,
    this.members = const [],
    this.pendingRequests = const [],
    this.activeSession,
    this.isLoading = false,
    this.isMutating = false,
  });

  int get pendingCount => pendingRequests.length;
  bool get isOwner => detail?.isOwner ?? false;

  ChannelDetailState copyWith({
    String? channelId,
    ChannelDetailModel? detail,
    List<ChannelMemberModel>? members,
    List<PairingRequestModel>? pendingRequests,
    PairingSessionModel? activeSession,
    bool clearSession = false,
    bool? isLoading,
    bool? isMutating,
  }) {
    return ChannelDetailState(
      channelId: channelId ?? this.channelId,
      detail: detail ?? this.detail,
      members: members ?? this.members,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeSession: clearSession ? null : (activeSession ?? this.activeSession),
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [
    channelId,
    detail,
    members,
    pendingRequests,
    activeSession,
    isLoading,
    isMutating,
  ];
}

// Backward-compatibility aliases
typedef ApprovalState = ChannelDetailState;
