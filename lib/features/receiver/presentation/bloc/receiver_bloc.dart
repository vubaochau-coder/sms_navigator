import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../data/models/received_otp_model.dart';
import '../../data/repositories/receiver_repository.dart';
import 'receiver_event.dart';
import 'receiver_state.dart';

class ReceiverBloc extends Bloc<ReceiverEvent, ReceiverState> {
  final ReceiverRepository repository;
  Timer? _pollTimer;
  StreamSubscription<ReceivedOtpModel>? _fcmSubscription;

  ReceiverBloc({required this.repository}) : super(const ReceiverState()) {
    on<ReceiverLoadOtpsEvent>(_onLoadOtps, transformer: restartable());
    on<ReceiverNewOtpPushedEvent>(_onNewOtpPushed, transformer: sequential());
    on<ReceiverClearHistoryEvent>(_onClearHistory, transformer: droppable());
    on<ReceiverPollPendingOtpsEvent>(
      _onPollPendingOtps,
      transformer: droppable(),
    );
    on<ReceiverStartSyncEvent>(_onStartSync, transformer: droppable());
    on<ReceiverStopSyncEvent>(_onStopSync, transformer: droppable());
  }

  Future<void> _onStartSync(ReceiverStartSyncEvent event, Emitter emit) async {
    _stopSyncInternal();

    _fcmSubscription = FcmNotificationService.onOtpReceived.listen((otp) {
      add(ReceiverNewOtpPushedEvent(otp));
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      add(const ReceiverPollPendingOtpsEvent());
    });

    add(const ReceiverLoadOtpsEvent());
  }

  void _onStopSync(ReceiverStopSyncEvent event, Emitter emit) {
    _stopSyncInternal();
  }

  void _stopSyncInternal() {
    _fcmSubscription?.cancel();
    _fcmSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _onLoadOtps(ReceiverLoadOtpsEvent event, Emitter emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final otps = await repository.fetchReceivedOtps();
      emit(state.copyWith(isLoading: false, otps: otps));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lỗi tải danh sách OTP: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onNewOtpPushed(
    ReceiverNewOtpPushedEvent event,
    Emitter emit,
  ) async {
    try {
      await repository.addNewOtp(event.otp);
      final otps = await repository.fetchReceivedOtps();
      emit(state.copyWith(otps: otps, latestPushedOtp: event.otp));
    } catch (_) {}
  }

  Future<void> _onClearHistory(
    ReceiverClearHistoryEvent event,
    Emitter emit,
  ) async {
    try {
      await repository.clearHistory();
      emit(state.copyWith(otps: const []));
    } catch (_) {}
  }

  Future<void> _onPollPendingOtps(
    ReceiverPollPendingOtpsEvent event,
    Emitter emit,
  ) async {
    try {
      final newCount = await repository.pollPendingOtps();
      if (newCount > 0) {
        final otps = await repository.fetchReceivedOtps();
        emit(state.copyWith(otps: otps));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _stopSyncInternal();
    return super.close();
  }
}
