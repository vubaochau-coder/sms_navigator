import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/channel_detail_model.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/repositories/channel_repository.dart';
import '../../../core/services/sync_owner_relay_channel_use_case.dart';
import '../../../core/utils/toast_utils.dart';
import 'channel_detail_event.dart';
import 'channel_detail_state.dart';
import 'channel_invite_bloc.dart';

export 'channel_detail_event.dart';
export 'channel_detail_state.dart';
export 'channel_invite_bloc.dart';

/// Bloc chi tiết kênh: hàng đợi duyệt + quản lý thành viên của Owner.
class ChannelDetailBloc extends Bloc<ChannelDetailEvent, ChannelDetailState> {
  ChannelDetailBloc({
    required ChannelRepository repository,
    required String channelId,
    SyncOwnerRelayChannelUseCase? syncUseCase,
  })  : _repository = repository,
        _syncUseCase = syncUseCase,
        super(ChannelDetailState(channelId: channelId)) {
    on<ChannelDetailLoaded>(_onLoaded, transformer: restartable());
    on<ChannelDetailConfirmed>(_onConfirmed, transformer: droppable());
    on<ChannelDetailRejected>(_onRejected, transformer: droppable());
    on<ChannelDetailMemberRevoked>(_onRevoked, transformer: droppable());
  }

  final ChannelRepository _repository;
  final SyncOwnerRelayChannelUseCase? _syncUseCase;

  Future<void> _refresh(Emitter<ChannelDetailState> emit) async {
    final results = await Future.wait([
      _repository.getChannelDetail(state.channelId),
      _repository.getMembers(state.channelId),
    ]);
    final detail = results[0] as ChannelDetailModel;
    final members = results[1] as List<ChannelMemberModel>;

    List<PairingRequestModel> pending = const [];
    if (detail.isOwner) {
      try {
        pending = await _repository.listPendingRequests(state.channelId);
        ChannelInviteBloc.invalidateIfConsumed(state.channelId, pending);
      } catch (_) {
        pending = const [];
      }
    }

    emit(
      state.copyWith(
        detail: detail,
        members: members,
        pendingRequests: pending,
        isLoading: false,
      ),
    );
  }

  Future<void> _onLoaded(ChannelDetailLoaded event, Emitter<ChannelDetailState> emit) async {
    emit(state.copyWith(channelId: event.channelId, isLoading: true));
    try {
      await _refresh(emit);
    } catch (error) {
      ToastUtils.showError(
        'Không tải được chi tiết kênh. Kiểm tra kết nối và thử lại.',
      );
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onConfirmed(
    ChannelDetailConfirmed event,
    Emitter<ChannelDetailState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      final newEpoch = await _repository.approveRequest(channelId: state.channelId, request: event.request);
      await _refresh(emit);
      if (_syncUseCase != null) {
        await _syncUseCase(channelId: state.channelId, expectedEpoch: newEpoch);
      }
      ToastUtils.showSuccess('Đã duyệt ${event.request.requesterDeviceName}.');
      emit(state.copyWith(isMutating: false));
    } catch (error) {
      // 409 MEMBERSHIP_CHANGED: state đã đổi → reload để Owner retry 1 chạm
      try {
        await _refresh(emit);
      } catch (_) {}
      ToastUtils.showError(
        'Không duyệt được: trạng thái kênh đã thay đổi. Danh sách đã được làm mới, thử lại.',
      );
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> _onRejected(
    ChannelDetailRejected event,
    Emitter<ChannelDetailState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repository.rejectRequest(event.request.requestId);
      await _refresh(emit);
      ToastUtils.showSuccess('Đã từ chối ${event.request.requesterDeviceName}.');
      emit(state.copyWith(isMutating: false));
    } catch (error) {
      try {
        await _refresh(emit);
      } catch (_) {}
      ToastUtils.showError('Không từ chối được: yêu cầu có thể đã được xử lý.');
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> _onRevoked(
    ChannelDetailMemberRevoked event,
    Emitter<ChannelDetailState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      final newEpoch = await _repository.revokeMembers(channelId: state.channelId, revokeDeviceIds: [event.deviceId]);
      await _refresh(emit);
      if (_syncUseCase != null) {
        await _syncUseCase(channelId: state.channelId, expectedEpoch: newEpoch);
      }
      ToastUtils.showSuccess('Đã thu hồi thành viên và xoay khóa kênh.');
      emit(state.copyWith(isMutating: false));
    } catch (error) {
      try {
        await _refresh(emit);
      } catch (_) {}
      ToastUtils.showError('Không thu hồi được: trạng thái kênh đã thay đổi. Thử lại.');
      emit(state.copyWith(isMutating: false));
    }
  }
}

// Backward-compatibility aliases
typedef ApprovalBloc = ChannelDetailBloc;
