import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/repositories/join_channel_repository.dart';
import '../../../core/repositories/qr_repository.dart';
import '../../../core/utils/qr_error_messages.dart';
import 'join_event.dart';
import 'join_state.dart';
import '../../../core/l10n/app_l10n.dart';

export 'join_event.dart';
export 'join_state.dart';

/// Bloc điều khiển luồng xác nhận tham gia kênh độc lập:
/// Resolve thông tin kênh -> Hiển thị Preview -> Submit Claim -> Pop.
class JoinBloc extends Bloc<JoinEvent, JoinState> {
  JoinBloc({
    required JoinChannelRepository repository,
    required String initialDeviceName,
    QrRepository? qrRepository,
  }) : _repository = repository,
       _qrRepository = qrRepository,
       super(JoinState(deviceName: initialDeviceName)) {
    on<JoinResolveStarted>(_onResolveStarted, transformer: restartable());
    on<JoinInitializedWithPreview>(_onInitializedWithPreview);
    on<JoinSubmitted>(_onSubmitted, transformer: droppable());
  }

  final JoinChannelRepository _repository;
  final QrRepository? _qrRepository;

  void _onInitializedWithPreview(
    JoinInitializedWithPreview event,
    Emitter<JoinState> emit,
  ) {
    emit(
      state.copyWith(
        phase: JoinPhase.ready,
        code: event.code,
        preview: event.preview,
        clearError: true,
      ),
    );
  }

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
    final code = state.code;
    final qrRepository = _qrRepository;
    final viaCode = code != null && qrRepository != null;
    if (!viaCode && invite == null) return;

    emit(
      state.copyWith(
        phase: JoinPhase.claiming,
        deviceName: event.deviceName,
        clearError: true,
      ),
    );

    try {
      final result = viaCode
          ? await qrRepository!.claimPairing(code: code!, deviceName: event.deviceName)
          : await _repository.claim(invite: invite!, deviceName: event.deviceName);
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

  String _mapResolveError(Object error, String? code) =>
      _mapJoinError(error, code) ?? AppL10n.current.joinResolveFailed;

  String _mapClaimError(Object error, String? code) =>
      _mapJoinError(error, code) ?? AppL10n.current.joinClaimFailed;

  /// Mã lỗi server → thông điệp dùng chung; dò chuỗi cho lỗi không mang errorCode.
  String? _mapJoinError(Object error, String? code) {
    final byCode = QrErrorMessages.forCode(code);
    if (byCode != null) return byCode;
    final raw = error.toString();
    if (raw.contains('REQUEST_ALREADY_PENDING')) return QrErrorMessages.forCode('REQUEST_ALREADY_PENDING');
    if (raw.contains('ALREADY_MEMBER')) return QrErrorMessages.forCode('ALREADY_MEMBER');
    if (raw.contains('QR_EXPIRED') || raw.contains('410')) return QrErrorMessages.forCode('QR_EXPIRED');
    if (raw.contains('QR_ALREADY_USED') || raw.contains('409')) return QrErrorMessages.forCode('QR_ALREADY_USED');
    return null;
  }
}
