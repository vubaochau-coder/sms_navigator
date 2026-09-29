import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/sender_repository.dart';
import 'sender_event.dart';
import 'sender_state.dart';

class SenderBloc extends Bloc<SenderEvent, SenderState> {
  final SenderRepository repository;

  SenderBloc({required this.repository}) : super(const SenderState()) {
    on<SenderLoadStatusEvent>(_onLoadStatus);
    on<SenderToggleRelayEvent>(_onToggleRelay);
    on<SenderRequestBatteryOptimizationEvent>(_onRequestBatteryOptimization);
    on<SenderUnpairEvent>(_onUnpair);
    on<SenderOtpDetectedEvent>(_onOtpDetected);

    repository.registerOtpListener((sender, otp) {
      add(SenderOtpDetectedEvent(sender, otp));
    });
  }

  Future<void> _onLoadStatus(
    SenderLoadStatusEvent event,
    Emitter<SenderState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final config = await repository.getRelayStatus();
      final logs = await repository.getRecentLogs();
      final isBatteryIgnored = await repository.checkBatteryOptimization();

      final pairId = config['pairId']?.toString() ?? '';
      final deviceId = config['deviceId']?.toString() ?? '';
      final isEnabled = config['isRelayEnabled'] == true;
      final isPaired = pairId.isNotEmpty;

      emit(state.copyWith(
        isLoading: false,
        isRelayEnabled: isEnabled,
        isPaired: isPaired,
        pairId: pairId,
        deviceId: deviceId,
        isBatteryOptimizationIgnored: isBatteryIgnored,
        logs: logs,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải trạng thái: ${e.toString()}',
      ));
    }
  }

  Future<void> _onToggleRelay(
    SenderToggleRelayEvent event,
    Emitter<SenderState> emit,
  ) async {
    try {
      final success = await repository.setRelayEnabled(event.isEnabled);
      if (success) {
        emit(state.copyWith(isRelayEnabled: event.isEnabled));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể thay đổi trạng thái: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRequestBatteryOptimization(
    SenderRequestBatteryOptimizationEvent event,
    Emitter<SenderState> emit,
  ) async {
    try {
      await repository.requestBatteryOptimization();
      final isIgnored = await repository.checkBatteryOptimization();
      emit(state.copyWith(isBatteryOptimizationIgnored: isIgnored));
    } catch (_) {}
  }

  Future<void> _onUnpair(
    SenderUnpairEvent event,
    Emitter<SenderState> emit,
  ) async {
    try {
      await repository.unpairDevice();
      emit(state.copyWith(
        isPaired: false,
        isRelayEnabled: false,
        pairId: '',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi hủy ghép đôi: ${e.toString()}'));
    }
  }

  Future<void> _onOtpDetected(
    SenderOtpDetectedEvent event,
    Emitter<SenderState> emit,
  ) async {
    final updatedLogs = await repository.getRecentLogs();
    emit(state.copyWith(
      lastDetectedOtp: event.otp,
      lastDetectedSender: event.sender,
      logs: updatedLogs,
    ));
  }
}
