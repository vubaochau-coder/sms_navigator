import 'package:equatable/equatable.dart';

import '../../../core/models/channel_model.dart';
import '../../../core/models/pairing_request_model.dart';

/// Trạng thái màn danh sách kênh: 2 nhóm "Kênh của bạn" (Owner) / "Kênh bạn
/// tham gia" (Member) — nguồn `GET /channels`, nhóm theo `role` (2.1),
/// kèm danh sách yêu cầu tham gia đang chờ duyệt (Member).
class ChannelState extends Equatable {
  final bool isLoading;
  final List<ChannelModel> ownedChannels;
  final List<ChannelModel> joinedChannels;
  final List<PairingRequestModel> pendingJoinRequests;
  final String? errorMessage;

  const ChannelState({
    this.isLoading = false,
    this.ownedChannels = const [],
    this.joinedChannels = const [],
    this.pendingJoinRequests = const [],
    this.errorMessage,
  });

  bool get isEmpty =>
      !isLoading &&
      errorMessage == null &&
      ownedChannels.isEmpty &&
      joinedChannels.isEmpty &&
      pendingJoinRequests.isEmpty;

  ChannelState copyWith({
    bool? isLoading,
    List<ChannelModel>? ownedChannels,
    List<ChannelModel>? joinedChannels,
    List<PairingRequestModel>? pendingJoinRequests,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChannelState(
      isLoading: isLoading ?? this.isLoading,
      ownedChannels: ownedChannels ?? this.ownedChannels,
      joinedChannels: joinedChannels ?? this.joinedChannels,
      pendingJoinRequests: pendingJoinRequests ?? this.pendingJoinRequests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, ownedChannels, joinedChannels, pendingJoinRequests, errorMessage];
}
