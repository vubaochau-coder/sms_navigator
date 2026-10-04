import 'package:equatable/equatable.dart';

import '../../../core/models/channel_model.dart';

/// Trạng thái màn danh sách kênh: 2 nhóm "Kênh của bạn" (Owner) / "Kênh bạn
/// tham gia" (Member) — nguồn `GET /channels`, nhóm theo `role` (2.1).
class ChannelState extends Equatable {
  final bool isLoading;
  final List<ChannelModel> ownedChannels;
  final List<ChannelModel> joinedChannels;
  final String? errorMessage;

  const ChannelState({
    this.isLoading = false,
    this.ownedChannels = const [],
    this.joinedChannels = const [],
    this.errorMessage,
  });

  bool get isEmpty =>
      !isLoading &&
      errorMessage == null &&
      ownedChannels.isEmpty &&
      joinedChannels.isEmpty;

  ChannelState copyWith({
    bool? isLoading,
    List<ChannelModel>? ownedChannels,
    List<ChannelModel>? joinedChannels,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChannelState(
      isLoading: isLoading ?? this.isLoading,
      ownedChannels: ownedChannels ?? this.ownedChannels,
      joinedChannels: joinedChannels ?? this.joinedChannels,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, ownedChannels, joinedChannels, errorMessage];
}
