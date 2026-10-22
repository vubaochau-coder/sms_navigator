import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/whitelist_config_model.dart';
import '../../../core/models/channel_detail_model.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/repositories/channel_repository.dart';
import '../../../core/usecases/sync_owner_relay_channel_use_case.dart';
import '../../../core/ui/toast_utils.dart';
import 'channel_detail_event.dart';
import 'channel_detail_state.dart';
import 'channel_invite_bloc.dart';
import '../../../core/l10n/app_l10n.dart';

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
    on<ChannelDetailRenamed>(_onRenamed, transformer: droppable());
    on<ChannelDetailLeft>(_onLeft, transformer: droppable());
    on<ChannelDetailArchived>(_onArchived, transformer: droppable());
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

    // Chỉ để xem — không bao giờ làm hỏng màn chi tiết
    WhitelistConfigModel? whitelist;
    try {
      whitelist = await _repository.readWhitelist(
        channelId: state.channelId,
        isOwner: detail.isOwner,
        blob: detail.whitelist,
      );
    } catch (_) {
      whitelist = null;
    }

    emit(
      state.copyWith(
        detail: detail,
        members: members,
        pendingRequests: pending,
        whitelist: whitelist,
        clearWhitelist: whitelist == null,
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
        AppL10n.current.channelDetailLoadFailed,
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
      ToastUtils.showSuccess(AppL10n.current.channelDetailApproved(event.request.requesterDeviceName));
      emit(state.copyWith(isMutating: false));
    } catch (error) {
      // 409 MEMBERSHIP_CHANGED: state đã đổi → reload để Owner retry 1 chạm
      try {
        await _refresh(emit);
      } catch (_) {}
      ToastUtils.showError(
        AppL10n.current.channelDetailApproveConflict,
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
      ToastUtils.showSuccess(AppL10n.current.channelDetailRejected(event.request.requesterDeviceName));
      emit(state.copyWith(isMutating: false));
    } catch (error) {
      try {
        await _refresh(emit);
      } catch (_) {}
      ToastUtils.showError(AppL10n.current.channelDetailRejectFailed);
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
      ToastUtils.showSuccess(AppL10n.current.channelDetailRevoked);
      emit(state.copyWith(isMutating: false));
    } catch (error) {
      try {
        await _refresh(emit);
      } catch (_) {}
      ToastUtils.showError(AppL10n.current.channelDetailRevokeConflict);
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> _onRenamed(
    ChannelDetailRenamed event,
    Emitter<ChannelDetailState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty || name == state.detail?.name) return;

    emit(state.copyWith(isMutating: true));
    try {
      await _repository.renameChannel(channelId: state.channelId, name: name);
      await _refresh(emit);
      // Native relay hiển thị tên kênh trong log relay — đồng bộ lại.
      if (_syncUseCase != null) {
        await _syncUseCase();
      }
      ToastUtils.showSuccess(AppL10n.current.channelRenameSuccess(name));
    } catch (error) {
      ToastUtils.showError(AppL10n.current.channelRenameFailed);
    }
    emit(state.copyWith(isMutating: false));
  }

  String get _channelName => state.detail?.name ?? '';

  Future<void> _onLeft(ChannelDetailLeft event, Emitter<ChannelDetailState> emit) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repository.leaveChannel(state.channelId);
      ToastUtils.showSuccess(AppL10n.current.channelLeaveSuccess(_channelName));
      emit(state.copyWith(isMutating: false, isClosed: true));
    } catch (error) {
      ToastUtils.showError(AppL10n.current.channelLeaveFailed);
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> _onArchived(ChannelDetailArchived event, Emitter<ChannelDetailState> emit) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repository.archiveChannel(state.channelId);
      // Kênh không còn trong danh sách → native ngừng relay cho kênh này.
      if (_syncUseCase != null) {
        await _syncUseCase();
      }
      ToastUtils.showSuccess(AppL10n.current.channelArchiveSuccess(_channelName));
      emit(state.copyWith(isMutating: false, isClosed: true));
    } catch (error) {
      ToastUtils.showError(AppL10n.current.channelArchiveFailed);
      emit(state.copyWith(isMutating: false));
    }
  }
}

// Backward-compatibility aliases
typedef ApprovalBloc = ChannelDetailBloc;
