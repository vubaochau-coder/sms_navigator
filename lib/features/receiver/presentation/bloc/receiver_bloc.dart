import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/receiver_repository.dart';
import 'receiver_event.dart';
import 'receiver_state.dart';

class ReceiverBloc extends Bloc<ReceiverEvent, ReceiverState> {
  final ReceiverRepository repository;

  ReceiverBloc({required this.repository}) : super(const ReceiverState()) {
    on<ReceiverLoadOtpsEvent>(_onLoadOtps);
    on<ReceiverNewOtpPushedEvent>(_onNewOtpPushed);
    on<ReceiverClearHistoryEvent>(_onClearHistory);
    on<ReceiverPollPendingOtpsEvent>(_onPollPendingOtps);
  }

  Future<void> _onLoadOtps(
    ReceiverLoadOtpsEvent event,
    Emitter<ReceiverState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final otps = await repository.fetchReceivedOtps();
      emit(state.copyWith(isLoading: false, otps: otps));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải danh sách OTP: ${e.toString()}',
      ));
    }
  }

  Future<void> _onNewOtpPushed(
    ReceiverNewOtpPushedEvent event,
    Emitter<ReceiverState> emit,
  ) async {
    try {
      await repository.addNewOtp(event.otp);
      final otps = await repository.fetchReceivedOtps();
      emit(state.copyWith(otps: otps));
    } catch (_) {}
  }

  Future<void> _onClearHistory(
    ReceiverClearHistoryEvent event,
    Emitter<ReceiverState> emit,
  ) async {
    try {
      await repository.clearHistory();
      emit(state.copyWith(otps: const []));
    } catch (_) {}
  }

  Future<void> _onPollPendingOtps(
    ReceiverPollPendingOtpsEvent event,
    Emitter<ReceiverState> emit,
  ) async {
    try {
      final newCount = await repository.pollPendingOtps();
      if (newCount > 0) {
        final otps = await repository.fetchReceivedOtps();
        emit(state.copyWith(otps: otps));
      }
    } catch (_) {}
  }
}
