import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/pairing_repository.dart';
import 'pairing_event.dart';
import 'pairing_state.dart';

class PairingBloc extends Bloc<PairingEvent, PairingState> {
  final PairingRepository repository;

  StreamSubscription<void>? _countdownSubscription;

  PairingBloc({required this.repository}) : super(const PairingState()) {
    on<PairingGenerateSenderCodeEvent>(
      (event, emit) async {
        await _onGenerateSenderCode(event, emit);
        if (state.pairingPayload != null && state.errorMessage == null) {
          emit(state.copyWith(
            countdownSeconds: PairingState.defaultCountdownSeconds,
          ));
          _startCountdown();
        }
      },
    );
    on<PairingTimerTickedEvent>(_onTimerTicked);
    on<PairingSubmitReceiverQrEvent>(_onSubmitReceiverQr);
    on<PairingCheckReceiverStatusEvent>(_onCheckReceiverStatus);
    on<PairingDisconnectReceiverEvent>(_onDisconnectReceiver);
  }

  void _startCountdown() {
    _countdownSubscription?.cancel();
    _countdownSubscription = Stream<void>.periodic(const Duration(seconds: 1))
        .listen((_) => add(const PairingTimerTickedEvent()));
  }

  void _onTimerTicked(
    PairingTimerTickedEvent event,
    Emitter<PairingState> emit,
  ) {
    final next = state.countdownSeconds - 1;
    if (next <= 0) {
      emit(state.copyWith(
        countdownSeconds: PairingState.defaultCountdownSeconds,
      ));
      add(const PairingGenerateSenderCodeEvent());
      return;
    }
    emit(state.copyWith(countdownSeconds: next));
  }

  @override
  Future<void> close() {
    _countdownSubscription?.cancel();
    _countdownSubscription = null;
    return super.close();
  }

  Future<void> _onGenerateSenderCode(
    PairingGenerateSenderCodeEvent event,
    Emitter<PairingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final payload = await repository.createSenderPairingSession();
      emit(state.copyWith(
        isLoading: false,
        pairingPayload: payload,
        isPaired: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tạo phiên ghép đôi: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSubmitReceiverQr(
    PairingSubmitReceiverQrEvent event,
    Emitter<PairingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: false));
    try {
      final success = await repository.submitReceiverPairingQr(event.qrData);
      if (success) {
        emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          isPaired: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Mã QR không hợp lệ hoặc đã hết hạn.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi xác nhận ghép đôi: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCheckReceiverStatus(
    PairingCheckReceiverStatusEvent event,
    Emitter<PairingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final payload = await repository.checkReceiverPairingStatus();
      emit(state.copyWith(
        isLoading: false,
        isPaired: payload != null,
        pairingPayload: payload,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onDisconnectReceiver(
    PairingDisconnectReceiverEvent event,
    Emitter<PairingState> emit,
  ) async {
    try {
      await repository.disconnectReceiver();
      emit(const PairingState(isPaired: false));
    } catch (_) {}
  }
}
