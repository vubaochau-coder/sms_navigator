import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/pairing_repository.dart';
import 'pairing_event.dart';
import 'pairing_state.dart';

class PairingBloc extends Bloc<PairingEvent, PairingState> {
  final PairingRepository repository;

  PairingBloc({required this.repository}) : super(const PairingState()) {
    on<PairingGenerateSenderCodeEvent>(_onGenerateSenderCode);
    on<PairingSubmitReceiverCodeEvent>(_onSubmitReceiverCode);
    on<PairingCheckReceiverStatusEvent>(_onCheckReceiverStatus);
    on<PairingDisconnectReceiverEvent>(_onDisconnectReceiver);
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

  Future<void> _onSubmitReceiverCode(
    PairingSubmitReceiverCodeEvent event,
    Emitter<PairingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: false));
    try {
      final success = await repository.submitReceiverPairingCode(event.code);
      if (success) {
        emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          isPaired: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Mã ghép đôi không hợp lệ. Vui lòng nhập đúng 6 số.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi xác nhận mã ghép đôi: ${e.toString()}',
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
