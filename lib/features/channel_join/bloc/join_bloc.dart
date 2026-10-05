import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/enums/join_phase.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/models/pairing_session_model.dart';
import '../../../core/repositories/join_channel_repository.dart';

export '../../../core/enums/join_phase.dart';

class JoinState extends Equatable {
  final JoinPhase phase;
  final InvitePayload? invite;
  final String channelName;
  final String ownerDeviceName;
  final String deviceName;
  final String? requestId;
  final List<PairingRequestModel> myRequests;
  final bool isSubmitting;
  final String? errorMessage;

  const JoinState({
    this.phase = JoinPhase.waitingApproval,
    this.invite,
    this.channelName = '',
    this.ownerDeviceName = '',
    this.deviceName = '',
    this.requestId,
    this.myRequests = const [],
    this.isSubmitting = false,
    this.errorMessage,
  });

  JoinState copyWith({
    JoinPhase? phase,
    InvitePayload? invite,
    String? channelName,
    String? ownerDeviceName,
    String? deviceName,
    String? requestId,
    List<PairingRequestModel>? myRequests,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JoinState(
      phase: phase ?? this.phase,
      invite: invite ?? this.invite,
      channelName: channelName ?? this.channelName,
      ownerDeviceName: ownerDeviceName ?? this.ownerDeviceName,
      deviceName: deviceName ?? this.deviceName,
      requestId: requestId ?? this.requestId,
      myRequests: myRequests ?? this.myRequests,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    phase,
    invite,
    channelName,
    ownerDeviceName,
    deviceName,
    requestId,
    myRequests,
    isSubmitting,
    errorMessage,
  ];
}

abstract class JoinEvent extends Equatable {
  const JoinEvent();

  @override
  List<Object?> get props => [];
}

/// Sau khi quét QR / mở deeplink: hiển thị dialog xác nhận (3.2).
class JoinInviteScanned extends JoinEvent {
  final InvitePayload invite;

  const JoinInviteScanned(this.invite);

  @override
  List<Object?> get props => [invite];
}

/// Bấm [Gửi yêu cầu kết nối] (3.3) — lúc này mới claim QR.
class JoinSubmitted extends JoinEvent {
  final String deviceName;

  const JoinSubmitted(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

/// Hủy request (3.5) — chỉ khi còn PENDING.
class JoinCancelled extends JoinEvent {
  const JoinCancelled();
}

/// Refresh trạng thái các request của tôi (reconcile khi mở app, SRD 7.3).
class JoinRequestsRefreshed extends JoinEvent {
  const JoinRequestsRefreshed();
}

/// Bloc luồng join của Member: quét → xác nhận → chờ duyệt → được cấp key.
class JoinBloc extends Bloc<JoinEvent, JoinState> {
  JoinBloc({
    required JoinChannelRepository repository,
    required String initialDeviceName,
  }) : _repository = repository,
       super(JoinState(deviceName: initialDeviceName)) {
    on<JoinInviteScanned>(_onInviteScanned);
    on<JoinSubmitted>(_onSubmitted, transformer: droppable());
    on<JoinCancelled>(_onCancelled, transformer: droppable());
    on<JoinRequestsRefreshed>(_onRefreshed, transformer: restartable());
  }

  final JoinChannelRepository _repository;

  Future<void> _onInviteScanned(
    JoinInviteScanned event,
    Emitter<JoinState> emit,
  ) async {
    // Không gọi API ở đây — chỉ chuyển sang dialog xác nhận (§18.2 SOLUTION).
    emit(
      state.copyWith(
        phase: JoinPhase.confirming,
        invite: event.invite,
        clearError: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    JoinSubmitted event,
    Emitter<JoinState> emit,
  ) async {
    final invite = state.invite;
    if (invite == null) return;
    emit(state.copyWith(isSubmitting: true, clearError: true, deviceName: event.deviceName));
    try {
      final result = await _repository.claim(
        invite: invite,
        deviceName: event.deviceName,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          phase: JoinPhase.waitingApproval,
          requestId: result.requestId,
          channelName: result.channelName,
          ownerDeviceName: result.ownerDeviceName,
        ),
      );
    } catch (error) {
      final message = _mapClaimError(error);
      emit(
        state.copyWith(
          isSubmitting: false,
          phase: JoinPhase.confirming,
          errorMessage: message,
        ),
      );
    }
  }

  /// Map mã lỗi server → thông điệp tiếng Việt + hướng dẫn (3.6, spec §2).
  String _mapClaimError(Object error) {
    final raw = error.toString();
    if (raw.contains('QR_EXPIRED') || raw.contains('410')) {
      return 'Mã mời đã hết hạn. Hãy xin Owner một mã mời mới.';
    }
    if (raw.contains('QR_ALREADY_USED') || raw.contains('409')) {
      return 'Mã mời đã được sử dụng. Hãy xin Owner một mã mời mới.';
    }
    return 'Không gửi được yêu cầu. Kiểm tra kết nối và thử lại.';
  }

  Future<void> _onCancelled(
    JoinCancelled event,
    Emitter<JoinState> emit,
  ) async {
    final requestId = state.requestId;
    if (requestId == null) return;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.cancelRequest(requestId);
      emit(state.copyWith(isSubmitting: false, phase: JoinPhase.confirming, requestId: null));
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Không hủy được yêu cầu. Thử lại sau.',
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    JoinRequestsRefreshed event,
    Emitter<JoinState> emit,
  ) async {
    try {
      final requests = await _repository.listMyRequests();
      final pending = requests.where((r) => r.isPending).toList();
      if (pending.isNotEmpty) {
        emit(
          state.copyWith(
            myRequests: requests,
            phase: JoinPhase.waitingApproval,
            requestId: pending.first.requestId,
            channelName: pending.first.channelName,
          ),
        );
        return;
      }
      final approved = requests
          .where((r) => r.status == PairingRequestStatus.approved)
          .toList();
      if (approved.isNotEmpty) {
        // Key provisioning ngầm (SRD 7.3): được duyệt → fetch envelope →
        // unwrap → persist. Chạy âm thầm, lỗi không phá UI.
        for (final request in approved) {
          await _repository.provisionLatestForApproved(channelId: request.channelId);
        }
      }
      emit(
        state.copyWith(
          myRequests: requests,
          phase: approved.isNotEmpty ? JoinPhase.approved : state.phase,
        ),
      );
    } catch (_) {
      // Reconcile là hành vi ngầm — lỗi im lặng, không phá UI
    }
  }
}
