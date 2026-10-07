import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/repositories/join_channel_repository.dart';
import 'join_event.dart';
import 'join_state.dart';

export 'join_event.dart';
export 'join_state.dart';

/// Bloc điều khiển luồng xác nhận tham gia kênh độc lập:
/// Resolve thông tin kênh -> Hiển thị Preview -> Submit Claim -> Pop.
class JoinBloc extends Bloc<JoinEvent, JoinState> {
  JoinBloc({
    required JoinChannelRepository repository,
    required String initialDeviceName,
  }) : _repository = repository,
       super(JoinState(deviceName: initialDeviceName)) {
    on<JoinResolveStarted>(_onResolveStarted, transformer: restartable());
    on<JoinSubmitted>(_onSubmitted, transformer: droppable());
  }

  final JoinChannelRepository _repository;

  Future<void> _onResolveStarted(
    JoinResolveStarted event,
    Emitter<JoinState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: JoinPhase.resolving,
        invite: event.invite,
        clearError: true,
      ),
    );

    try {
      final preview = await _repository.resolveInvite(event.invite);
      emit(
        state.copyWith(
          phase: JoinPhase.ready,
          preview: preview,
          clearError: true,
        ),
      );
    } catch (error) {
      final code = _extractErrorCode(error);
      final message = _mapResolveError(error, code);
      emit(
        state.copyWith(
          phase: JoinPhase.resolveFailed,
          errorMessage: message,
          errorCode: code,
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    JoinSubmitted event,
    Emitter<JoinState> emit,
  ) async {
    final invite = state.invite;
    if (invite == null) return;

    emit(
      state.copyWith(
        phase: JoinPhase.claiming,
        deviceName: event.deviceName,
        clearError: true,
      ),
    );

    try {
      final result = await _repository.claim(
        invite: invite,
        deviceName: event.deviceName,
      );
      emit(
        state.copyWith(
          phase: JoinPhase.claimSuccess,
          requestId: result.requestId,
          clearError: true,
        ),
      );
    } catch (error) {
      final code = _extractErrorCode(error);
      final message = _mapClaimError(error, code);
      emit(
        state.copyWith(
          phase: JoinPhase.claimFailed,
          errorMessage: message,
          errorCode: code,
        ),
      );
    }
  }

  String? _extractErrorCode(Object error) {
    if (error is ApiException) return error.errorCode;
    return null;
  }

  String _mapResolveError(Object error, String? code) {
    if (code == 'REQUEST_ALREADY_PENDING') {
      return 'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.';
    }
    if (code == 'ALREADY_MEMBER') {
      return 'Thiết bị của bạn đã là thành viên của kênh này.';
    }
    if (code == 'QR_EXPIRED') {
      return 'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.';
    }
    if (code == 'QR_ALREADY_USED') {
      return 'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.';
    }
    if (code == 'CHANNEL_NOT_ACTIVE') {
      return 'Kênh này đã bị lưu trữ, không thể tham gia.';
    }
    final raw = error.toString();
    if (raw.contains('REQUEST_ALREADY_PENDING')) {
      return 'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.';
    }
    if (raw.contains('ALREADY_MEMBER')) {
      return 'Thiết bị của bạn đã là thành viên của kênh này.';
    }
    if (raw.contains('QR_EXPIRED') || raw.contains('410')) {
      return 'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.';
    }
    if (raw.contains('QR_ALREADY_USED') || raw.contains('409')) {
      return 'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.';
    }
    return 'Không thể kiểm tra thông tin kênh. Vui lòng thử lại sau.';
  }

  String _mapClaimError(Object error, String? code) {
    if (code == 'REQUEST_ALREADY_PENDING') {
      return 'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.';
    }
    if (code == 'ALREADY_MEMBER') {
      return 'Thiết bị của bạn đã là thành viên của kênh này.';
    }
    if (code == 'QR_EXPIRED') {
      return 'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.';
    }
    if (code == 'QR_ALREADY_USED') {
      return 'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.';
    }
    if (code == 'CHANNEL_NOT_ACTIVE') {
      return 'Kênh này đã bị lưu trữ, không thể tham gia.';
    }
    final raw = error.toString();
    if (raw.contains('REQUEST_ALREADY_PENDING')) {
      return 'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.';
    }
    if (raw.contains('ALREADY_MEMBER')) {
      return 'Thiết bị của bạn đã là thành viên của kênh này.';
    }
    if (raw.contains('QR_EXPIRED') || raw.contains('410')) {
      return 'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.';
    }
    if (raw.contains('QR_ALREADY_USED') || raw.contains('409')) {
      return 'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.';
    }
    return 'Không gửi được yêu cầu. Kiểm tra kết nối và thử lại.';
  }
}
