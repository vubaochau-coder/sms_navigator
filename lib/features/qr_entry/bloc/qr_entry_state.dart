import 'package:equatable/equatable.dart';

import '../../../core/models/qr_resolution.dart';

enum QrEntryPhase { resolving, resolved, failed }

class QrEntryState extends Equatable {
  final QrEntryPhase phase;
  final QrResolution? resolution;
  final String? errorMessage;
  final String? errorCode;

  const QrEntryState({
    this.phase = QrEntryPhase.resolving,
    this.resolution,
    this.errorMessage,
    this.errorCode,
  });

  bool get isAlreadyPending => errorCode == 'REQUEST_ALREADY_PENDING';

  QrEntryState copyWith({
    QrEntryPhase? phase,
    QrResolution? resolution,
    String? errorMessage,
    String? errorCode,
  }) {
    return QrEntryState(
      phase: phase ?? this.phase,
      resolution: resolution ?? this.resolution,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [phase, resolution, errorMessage, errorCode];
}
