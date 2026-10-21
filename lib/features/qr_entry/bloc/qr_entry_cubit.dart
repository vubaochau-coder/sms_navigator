import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/qr_resolution.dart';
import '../../../core/repositories/qr_repository.dart';
import '../../../core/utils/qr_error_messages.dart';
import 'qr_entry_state.dart';

export 'qr_entry_state.dart';

/// QR Analyzer (roadmap v3.3 §3.3): code → `GET /qr/resolve` → nghiệp vụ đích.
class QrEntryCubit extends Cubit<QrEntryState> {
  QrEntryCubit({required QrRepository repository})
    : _repository = repository,
      super(const QrEntryState());

  final QrRepository _repository;

  Future<void> resolve(String code) async {
    emit(const QrEntryState(phase: QrEntryPhase.resolving));
    try {
      final resolution = await _repository.resolve(code);
      if (isClosed) return;
      if (resolution is UnsupportedQrResolution) {
        emit(const QrEntryState(
          phase: QrEntryPhase.failed,
          errorMessage: QrErrorMessages.updateRequired,
          errorCode: 'UNSUPPORTED_QR_TYPE',
        ));
        return;
      }
      emit(QrEntryState(phase: QrEntryPhase.resolved, resolution: resolution));
    } catch (error) {
      if (isClosed) return;
      emit(QrEntryState(
        phase: QrEntryPhase.failed,
        errorMessage: QrErrorMessages.forError(error),
        errorCode: QrErrorMessages.codeOf(error),
      ));
    }
  }
}
