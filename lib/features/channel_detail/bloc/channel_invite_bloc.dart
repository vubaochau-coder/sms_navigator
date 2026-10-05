import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/channel_repository.dart';
import '../../../core/utils/toast_utils.dart';
import 'channel_invite_event.dart';
import 'channel_invite_state.dart';

export 'channel_invite_event.dart';
export 'channel_invite_state.dart';

/// Bloc quản lý riêng cho BottomSheet tạo và làm mới mã QR mời tham gia kênh.
/// Vòng đời hoàn toàn độc lập với ChannelDetailBloc:
/// - Tự khởi tạo và tạo session khi mở Sheet
/// - Tự dispose và giải phóng bộ nhớ khi đóng Sheet (không cần logic reset thủ công)
class ChannelInviteBloc extends Bloc<ChannelInviteEvent, ChannelInviteState> {
  ChannelInviteBloc({
    required ChannelRepository repository,
    required String channelId,
  })  : _repository = repository,
        super(ChannelInviteState(channelId: channelId)) {
    on<ChannelInviteStarted>(_onStarted, transformer: droppable());
    on<ChannelInviteRegenerated>(_onRegenerated, transformer: droppable());
  }

  final ChannelRepository _repository;

  Future<void> _createSession(Emitter<ChannelInviteState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final session = await _repository.createPairingSession(state.channelId);
      emit(state.copyWith(isLoading: false, session: session));
    } catch (error) {
      const msg = 'Không tạo được mã mời. Thử lại sau.';
      ToastUtils.showError(msg);
      emit(state.copyWith(isLoading: false, errorMessage: msg));
    }
  }

  Future<void> _onStarted(
    ChannelInviteStarted event,
    Emitter<ChannelInviteState> emit,
  ) async {
    if (state.session == null || state.isExpired) {
      await _createSession(emit);
    }
  }

  Future<void> _onRegenerated(
    ChannelInviteRegenerated event,
    Emitter<ChannelInviteState> emit,
  ) async {
    await _createSession(emit);
  }
}
