import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/pairing_request_model.dart';
import '../../../core/repositories/join_channel_repository.dart';
import 'join_event.dart';
import 'join_state.dart';

export 'join_event.dart';
export 'join_state.dart';

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
