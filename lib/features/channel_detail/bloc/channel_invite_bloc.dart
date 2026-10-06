import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/pairing_request_model.dart';
import '../../../core/models/pairing_session_model.dart';
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
        super(ChannelInviteState(
          channelId: channelId,
          session: _activeSession(channelId),
        )) {
    on<ChannelInviteStarted>(_onStarted, transformer: droppable());
    on<ChannelInviteRegenerated>(_onRegenerated, transformer: droppable());
  }

  final ChannelRepository _repository;

  /// Cache in-memory session còn hiệu lực theo kênh để giữ mã QR khi đóng/mở lại Sheet
  static final Map<String, PairingSessionModel> _activeSessions = {};

  static PairingSessionModel? _activeSession(String channelId) {
    final cached = _activeSessions[channelId];
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    _activeSessions.remove(channelId);
    return null;
  }

  static PairingSessionModel? activeSession(String channelId) =>
      _activeSession(channelId);

  static void invalidateCache(String channelId) {
    _activeSessions.remove(channelId);
  }

  /// Hủy cache nếu có bất kỳ pending request nào được gửi tại/sau thời điểm tạo cached session.
  /// (QR code đã được quét và gửi yêu cầu, không còn UNUSED trên server).
  static void invalidateIfConsumed(
    String channelId,
    List<PairingRequestModel> pendingRequests,
  ) {
    final session = _activeSessions[channelId];
    if (session == null) return;
    final sessionCreated = session.effectiveCreatedAt;
    final hasConsumedRequest = pendingRequests.any((req) {
      final reqCreated = DateTime.tryParse(req.createdAt);
      if (reqCreated == null) return false;
      // Trừ 5 giây đệm cho sai lệch đồng hồ client/server
      return reqCreated.isAfter(
        sessionCreated.subtract(const Duration(seconds: 5)),
      );
    });
    if (hasConsumedRequest) {
      _activeSessions.remove(channelId);
    }
  }

  Future<void> _createSession(Emitter<ChannelInviteState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final session = await _repository.createPairingSession(state.channelId);
      _activeSessions[state.channelId] = session;
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
