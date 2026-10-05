import 'package:equatable/equatable.dart';

import '../../../core/models/pairing_session_model.dart';

/// Trạng thái của BottomSheet mời tham gia kênh.
class ChannelInviteState extends Equatable {
  final String channelId;
  final PairingSessionModel? session;
  final bool isLoading;
  final String? errorMessage;

  const ChannelInviteState({
    required this.channelId,
    this.session,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isExpired => session?.isExpired ?? false;

  ChannelInviteState copyWith({
    String? channelId,
    PairingSessionModel? session,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChannelInviteState(
      channelId: channelId ?? this.channelId,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [channelId, session, isLoading, errorMessage];
}
