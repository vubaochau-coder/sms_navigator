import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/channel_detail_model.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/models/pairing_session_model.dart';
import '../../../core/repositories/channel_repository.dart';
import '../../../core/utils/toast_utils.dart';

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

abstract class ChannelDetailEvent extends Equatable {
  const ChannelDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Mở màn chi tiết / refresh khi mở app (4.1).
class ChannelDetailLoaded extends ChannelDetailEvent {
  final String channelId;

  const ChannelDetailLoaded(this.channelId);

  @override
  List<Object?> get props => [channelId];
}

/// Tạo/làm mới QR invitation (2.3) — countdown 10'.
class ChannelDetailSessionCreated extends ChannelDetailEvent {
  final String channelId;

  const ChannelDetailSessionCreated(this.channelId);

  @override
  List<Object?> get props => [channelId];
}

/// Approve member (4.2) — dialog xác nhận rồi mới gọi; bên trong tự rotate.
class ChannelDetailConfirmed extends ChannelDetailEvent {
  final PairingRequestModel request;

  const ChannelDetailConfirmed(this.request);

  @override
  List<Object?> get props => [request];
}

/// Reject request (4.3) — dialog xác nhận màu đỏ; mã QR đã cháy.
class ChannelDetailRejected extends ChannelDetailEvent {
  final PairingRequestModel request;

  const ChannelDetailRejected(this.request);

  @override
  List<Object?> get props => [request];
}

/// Revoke member (4.4) — dialog cảnh báo mức cao; tự rotate key.
class ChannelDetailMemberRevoked extends ChannelDetailEvent {
  final String deviceId;

  const ChannelDetailMemberRevoked(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

/// Bloc chi tiết kênh: hàng đợi duyệt + quản lý thành viên của Owner.
class ChannelDetailBloc extends Bloc<ChannelDetailEvent, ChannelDetailState> {
  ChannelDetailBloc({required ChannelRepository repository, required String channelId})
    : _repository = repository,
      super(ChannelDetailState(channelId: channelId)) {
    on<ChannelDetailLoaded>(_onLoaded, transformer: restartable());
    on<ChannelDetailSessionCreated>(_onSessionCreated, transformer: droppable());
    on<ChannelDetailConfirmed>(_onConfirmed, transformer: droppable());
    on<ChannelDetailRejected>(_onRejected, transformer: droppable());
    on<ChannelDetailMemberRevoked>(_onRevoked, transformer: droppable());
  }

  final ChannelRepository _repository;

  Future<void> _refresh(Emitter<ChannelDetailState> emit) async {
    final results = await Future.wait([
      _repository.getChannelDetail(state.channelId),
      _repository.getMembers(state.channelId),
      _repository.listPendingRequests(state.channelId),
    ]);
    emit(
      state.copyWith(
        detail: results[0] as ChannelDetailModel,
        members: results[1] as List<ChannelMemberModel>,
        pendingRequests: results[2] as List<PairingRequestModel>,
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

  Future<void> _onSessionCreated(
    ChannelDetailSessionCreated event,
    Emitter<ChannelDetailState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      final session = await _repository.createPairingSession(state.channelId);
      emit(state.copyWith(isMutating: false, activeSession: session));
    } catch (error) {
      ToastUtils.showError('Không tạo được mã mời. Thử lại sau.');
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> _onConfirmed(
    ChannelDetailConfirmed event,
    Emitter<ChannelDetailState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repository.approveRequest(channelId: state.channelId, request: event.request);
      await _refresh(emit);
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
      await _repository.revokeMembers(channelId: state.channelId, revokeDeviceIds: [event.deviceId]);
      await _refresh(emit);
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
typedef ApprovalState = ChannelDetailState;
typedef ApprovalEvent = ChannelDetailEvent;
typedef ApprovalLoaded = ChannelDetailLoaded;
typedef ApprovalSessionCreated = ChannelDetailSessionCreated;
typedef ApprovalConfirmed = ChannelDetailConfirmed;
typedef ApprovalRejected = ChannelDetailRejected;
typedef ApprovalMemberRevoked = ChannelDetailMemberRevoked;
