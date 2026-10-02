import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../data/repositories/pairing_repository.dart';
import '../../data/services/qr_image_export_service.dart';
import 'pairing_event.dart';
import 'pairing_state.dart';

class PairingBloc extends Bloc<PairingEvent, PairingState> {
  final PairingRepository repository;

  StreamSubscription<void>? _countdownSubscription;

  /// Poll trạng thái liên kết phía Máy A (xem [_startLinkPolling]).
  Timer? _linkPollTimer;

  static const Duration _linkPollInterval = Duration(seconds: 5);

  PairingBloc({required this.repository}) : super(const PairingState()) {
    on<PairingGenerateSenderCodeEvent>((event, emit) async {
      await _onGenerateSenderCode(event, emit);
      if (state.pairingPayload != null && state.errorMessage == null) {
        emit(
          state.copyWith(
            countdownSeconds: PairingState.defaultCountdownSeconds,
          ),
        );
        _startCountdown();
        _startLinkPolling();
      }
    }, transformer: droppable());
    on<PairingTimerTickedEvent>(_onTimerTicked, transformer: sequential());
    on<PairingSubmitReceiverQrEvent>(
      _onSubmitReceiverQr,
      transformer: droppable(),
    );
    on<PairingCheckReceiverStatusEvent>(
      _onCheckReceiverStatus,
      transformer: restartable(),
    );
    on<PairingSenderLinkPolled>(_onSenderLinkPolled, transformer: droppable());
    on<PairingExportQrRequested>(
      _onExportQrRequested,
      transformer: droppable(),
    );
    on<PairingDisconnectReceiverEvent>(
      _onDisconnectReceiver,
      transformer: droppable(),
    );
  }

  void _startCountdown() {
    _countdownSubscription?.cancel();
    _countdownSubscription = Stream<void>.periodic(
      const Duration(seconds: 1),
    ).listen((_) => add(const PairingTimerTickedEvent()));
  }

  /// Máy A: poll `/pair/status` định kỳ tới khi Máy B confirm. Lượng request
  /// rất nhỏ (1 lần / 5 giây, dừng ngay khi linked) — không phải polling
  /// chờ duyệt, chỉ là phát hiện liên kết hoàn tất.
  void _startLinkPolling() {
    _linkPollTimer?.cancel();
    if (state.pairingPayload?.senderPrivateKeyBase64 == null ||
        (state.pairingPayload?.senderPrivateKeyBase64.isEmpty ?? true)) {
      return;
    }
    _linkPollTimer = Timer.periodic(
      _linkPollInterval,
      (_) => add(const PairingSenderLinkPolled()),
    );
  }

  void _stopLinkPolling() {
    _linkPollTimer?.cancel();
    _linkPollTimer = null;
  }

  void _onTimerTicked(PairingTimerTickedEvent event, Emitter emit) {
    // Đã linked: QR đã được tiêu — không xoay mã nữa.
    if (state.isReceiverLinked) return;
    final next = state.countdownSeconds - 1;
    if (next <= 0) {
      emit(
        state.copyWith(countdownSeconds: PairingState.defaultCountdownSeconds),
      );
      add(const PairingGenerateSenderCodeEvent());
      return;
    }
    emit(state.copyWith(countdownSeconds: next));
  }

  @override
  Future<void> close() {
    _countdownSubscription?.cancel();
    _countdownSubscription = null;
    _stopLinkPolling();
    return super.close();
  }

  Future<void> _onGenerateSenderCode(
    PairingGenerateSenderCodeEvent event,
    Emitter emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        isReceiverLinked: false,
      ),
    );
    try {
      final payload = await repository.createSenderPairingSession();
      emit(
        state.copyWith(
          isLoading: false,
          pairingPayload: payload,
          isPaired: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lỗi tạo phiên ghép đôi: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSenderLinkPolled(
    PairingSenderLinkPolled event,
    Emitter emit,
  ) async {
    final payload = state.pairingPayload;
    if (payload == null ||
        state.isReceiverLinked ||
        payload.senderPrivateKeyBase64.isEmpty) {
      return;
    }
    try {
      final status = await repository.checkSenderPairingLink(payload);
      if (status.linked && !state.isReceiverLinked) {
        _stopLinkPolling();
        emit(state.copyWith(isReceiverLinked: true));
      }
    } catch (_) {
      // Lỗi tạm thời (mạng, server): im lặng, tick sau thử lại.
    }
  }

  Future<void> _onSubmitReceiverQr(
    PairingSubmitReceiverQrEvent event,
    Emitter emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: false));
    try {
      final success = await repository.submitReceiverPairingQr(event.qrData);
      if (success) {
        emit(state.copyWith(isLoading: false, isSuccess: true, isPaired: true));
        ToastUtils.showSuccess('Ghép đôi thiết bị thành công!');
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Mã QR không hợp lệ hoặc đã hết hạn.',
          ),
        );
        ToastUtils.showError('Mã QR không hợp lệ hoặc đã hết hạn.');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lỗi xác nhận ghép đôi: ${e.toString()}',
        ),
      );
      ToastUtils.showError('Lỗi xác nhận ghép đôi: ${e.toString()}');
    }
  }

  Future<void> _onCheckReceiverStatus(
    PairingCheckReceiverStatusEvent event,
    Emitter emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final payload = await repository.checkReceiverPairingStatus();
      emit(
        state.copyWith(
          isLoading: false,
          isPaired: payload != null,
          pairingPayload: payload,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onExportQrRequested(
    PairingExportQrRequested event,
    Emitter emit,
  ) async {
    final payload = state.pairingPayload;
    if (payload == null) {
      emit(
        state.copyWith(
          qrExportStatus: QrExportStatus.noQr,
          qrExportToken: state.qrExportToken + 1,
        ),
      );
      return;
    }
    emit(state.copyWith(isExportingQr: true, qrExportStatus: null));
    try {
      await repository.exportPairingQr(payload);
      emit(
        state.copyWith(
          isExportingQr: false,
          qrExportStatus: QrExportStatus.success,
          qrExportToken: state.qrExportToken + 1,
        ),
      );
    } on QrImageExportException catch (e) {
      emit(
        state.copyWith(
          isExportingQr: false,
          qrExportStatus: e.accessDenied
              ? QrExportStatus.permissionDenied
              : QrExportStatus.genericFailure,
          qrExportToken: state.qrExportToken + 1,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isExportingQr: false,
          qrExportStatus: QrExportStatus.genericFailure,
          qrExportToken: state.qrExportToken + 1,
        ),
      );
    }
  }

  Future<void> _onDisconnectReceiver(
    PairingDisconnectReceiverEvent event,
    Emitter emit,
  ) async {
    try {
      await repository.disconnectReceiver();
      emit(const PairingState(isPaired: false));
      ToastUtils.showSuccess('Đã hủy kết nối thiết bị');
    } catch (_) {
      ToastUtils.showError('Không thể hủy kết nối thiết bị');
    }
  }
}
