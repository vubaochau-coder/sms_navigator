import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/channel_detail_model.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/models/pairing_session_model.dart';
import '../../../core/repositories/channel_repository.dart';

/// Trạng thái màn chi tiết kênh của Owner: members + hàng đợi duyệt + QR
/// invite đang hiệu lực (2.3, 4.1–4.4). Badge = pendingCount.
class ApprovalState extends Equatable {
  final String channelId;
  final ChannelDetailModel? detail;
  final List<ChannelMemberModel> members;
  final List<PairingRequestModel> pendingRequests;
  final PairingSessionModel? activeSession;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final String? successMessage;

  const ApprovalState({
    required this.channelId,
    this.detail,
    this.members = const [],
    this.pendingRequests = const [],
    this.activeSession,
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.successMessage,
  });

  int get pendingCount => pendingRequests.length;
  bool get isOwner => detail?.isOwner ?? false;

  ApprovalState copyWith({
    String? channelId,
    ChannelDetailModel? detail,
    List<ChannelMemberModel>? members,
    List<PairingRequestModel>? pendingRequests,
    PairingSessionModel? activeSession,
    bool clearSession = false,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ApprovalState(
      channelId: channelId ?? this.channelId,
      detail: detail ?? this.detail,
      members: members ?? this.members,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeSession: clearSession ? null : (activeSession ?? this.activeSession),
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
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
    errorMessage,
    successMessage,
  ];
}

abstract class ApprovalEvent extends Equatable {
  const ApprovalEvent();

  @override
  List<Object?> get props => [];
}

/// Mở màn chi tiết / refresh khi mở app (4.1).
class ApprovalLoaded extends ApprovalEvent {
  final String channelId;

  const ApprovalLoaded(this.channelId);

  @override
  List<Object?> get props => [channelId];
}

/// Tạo/làm mới QR invitation (2.3) — countdown 10'.
class ApprovalSessionCreated extends ApprovalEvent {
  final String channelId;

  const ApprovalSessionCreated(this.channelId);

  @override
  List<Object?> get props => [channelId];
}

/// Approve member (4.2) — dialog xác nhận rồi mới gọi; bên trong tự rotate.
class ApprovalConfirmed extends ApprovalEvent {
  final PairingRequestModel request;

  const ApprovalConfirmed(this.request);

  @override
  List<Object?> get props => [request];
}

/// Reject request (4.3) — dialog xác nhận màu đỏ; mã QR đã cháy.
class ApprovalRejected extends ApprovalEvent {
  final PairingRequestModel request;

  const ApprovalRejected(this.request);

  @override
  List<Object?> get props => [request];
}

/// Revoke member (4.4) — dialog cảnh báo mức cao; tự rotate key.
class ApprovalMemberRevoked extends ApprovalEvent {
  final String deviceId;

  const ApprovalMemberRevoked(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

/// Bloc hàng đợi duyệt + quản lý thành viên của Owner.
class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  ApprovalBloc({required ChannelRepository repository, required String channelId})
    : _repository = repository,
      super(ApprovalState(channelId: channelId)) {
    on<ApprovalLoaded>(_onLoaded, transformer: restartable());
    on<ApprovalSessionCreated>(_onSessionCreated, transformer: droppable());
    on<ApprovalConfirmed>(_onConfirmed, transformer: droppable());
    on<ApprovalRejected>(_onRejected, transformer: droppable());
    on<ApprovalMemberRevoked>(_onRevoked, transformer: droppable());
  }

  final ChannelRepository _repository;

  Future<void> _refresh(Emitter<ApprovalState> emit) async {
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
        clearError: true,
      ),
    );
  }

  Future<void> _onLoaded(ApprovalLoaded event, Emitter<ApprovalState> emit) async {
    emit(state.copyWith(channelId: event.channelId, isLoading: true));
    try {
      await _refresh(emit);
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không tải được chi tiết kênh. Kiểm tra kết nối và thử lại.',
        ),
      );
    }
  }

  Future<void> _onSessionCreated(
    ApprovalSessionCreated event,
    Emitter<ApprovalState> emit,
  ) async {
    emit(state.copyWith(isMutating: true, clearError: true));
    try {
      final session = await _repository.createPairingSession(state.channelId);
      emit(state.copyWith(isMutating: false, activeSession: session));
    } catch (error) {
      emit(
        state.copyWith(
          isMutating: false,
          errorMessage: 'Không tạo được mã mời. Thử lại sau.',
        ),
      );
    }
  }

  Future<void> _onConfirmed(
    ApprovalConfirmed event,
    Emitter<ApprovalState> emit,
  ) async {
    emit(state.copyWith(isMutating: true, clearError: true, clearSuccess: true));
    try {
      await _repository.approveRequest(channelId: state.channelId, request: event.request);
      await _refresh(emit);
      emit(
        state.copyWith(
          isMutating: false,
          successMessage: 'Đã duyệt ${event.request.requesterDeviceName}.',
        ),
      );
    } catch (error) {
      // 409 MEMBERSHIP_CHANGED: state đã đổi → reload để Owner retry 1 chạm
      try {
        await _refresh(emit);
      } catch (_) {}
      emit(
        state.copyWith(
          isMutating: false,
          errorMessage:
              'Không duyệt được: trạng thái kênh đã thay đổi. Danh sách đã được làm mới, thử lại.',
        ),
      );
    }
  }

  Future<void> _onRejected(
    ApprovalRejected event,
    Emitter<ApprovalState> emit,
  ) async {
    emit(state.copyWith(isMutating: true, clearError: true, clearSuccess: true));
    try {
      await _repository.rejectRequest(event.request.requestId);
      await _refresh(emit);
      emit(
        state.copyWith(
          isMutating: false,
          successMessage: 'Đã từ chối ${event.request.requesterDeviceName}.',
        ),
      );
    } catch (error) {
      try {
        await _refresh(emit);
      } catch (_) {}
      emit(
        state.copyWith(
          isMutating: false,
          errorMessage: 'Không từ chối được: yêu cầu có thể đã được xử lý.',
        ),
      );
    }
  }

  Future<void> _onRevoked(
    ApprovalMemberRevoked event,
    Emitter<ApprovalState> emit,
  ) async {
    emit(state.copyWith(isMutating: true, clearError: true, clearSuccess: true));
    try {
      await _repository.revokeMembers(channelId: state.channelId, revokeDeviceIds: [event.deviceId]);
      await _refresh(emit);
      emit(
        state.copyWith(
          isMutating: false,
          successMessage: 'Đã thu hồi thành viên và xoay khóa kênh.',
        ),
      );
    } catch (error) {
      try {
        await _refresh(emit);
      } catch (_) {}
      emit(
        state.copyWith(
          isMutating: false,
          errorMessage: 'Không thu hồi được: trạng thái kênh đã thay đổi. Thử lại.',
        ),
      );
    }
  }
}
