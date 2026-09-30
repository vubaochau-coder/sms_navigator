import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/repositories/sender_repository.dart';
import 'sender_event.dart';
import 'sender_state.dart';

class SenderBloc extends Bloc<SenderEvent, SenderState> {
  final SenderRepository repository;

  SenderBloc({required this.repository}) : super(const SenderState()) {
    on<SenderLoadStatusEvent>(_onLoadStatus, transformer: restartable());
    on<SenderCheckSmsPermissionEvent>(_onCheckSmsPermission, transformer: droppable());
    on<SenderToggleRelayEvent>(_onToggleRelay, transformer: droppable());
    on<SenderUpdateRelayModeEvent>(_onUpdateRelayMode, transformer: droppable());
    on<SenderAddWhitelistPrefixEvent>(_onAddWhitelistPrefix, transformer: droppable());
    on<SenderRemoveWhitelistPrefixEvent>(_onRemoveWhitelistPrefix, transformer: droppable());
    on<SenderRequestBatteryOptimizationEvent>(_onRequestBatteryOptimization, transformer: droppable());
    on<SenderUnpairEvent>(_onUnpair, transformer: droppable());
    on<SenderOtpDetectedEvent>(_onOtpDetected, transformer: sequential());

    repository.registerOtpListener((sender, otp) {
      add(SenderOtpDetectedEvent(sender, otp));
    });
  }

  Future<void> _onCheckSmsPermission(
    SenderCheckSmsPermissionEvent event,
    Emitter<SenderState> emit,
  ) async {
    try {
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        await Permission.sms.request();
      }
    } catch (_) {}
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
      final relayMode = config['relayMode']?.toString() ?? 'OTP_ONLY';
      final rawWhitelist = config['senderWhitelist'];
      final List<String> senderWhitelist = (rawWhitelist is List)
          ? rawWhitelist.map((e) => e.toString()).toList()
          : <String>[];
      final isPaired = pairId.isNotEmpty;

      emit(state.copyWith(
        isLoading: false,
        isRelayEnabled: isEnabled,
        relayMode: relayMode,
        senderWhitelist: senderWhitelist,
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

  Future<void> _onUpdateRelayMode(
    SenderUpdateRelayModeEvent event,
    Emitter<SenderState> emit,
  ) async {
    try {
      final success = await repository.setRelayMode(event.relayMode);
      if (success) {
        emit(state.copyWith(relayMode: event.relayMode));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể cập nhật chế độ chuyển tiếp: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddWhitelistPrefix(
    SenderAddWhitelistPrefixEvent event,
    Emitter<SenderState> emit,
  ) async {
    final clean = event.prefix.trim();
    if (clean.isEmpty || state.senderWhitelist.contains(clean)) return;

    final updated = List<String>.from(state.senderWhitelist)..add(clean);
    try {
      final success = await repository.setSenderWhitelist(updated);
      if (success) {
        emit(state.copyWith(senderWhitelist: updated));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể thêm đầu số: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRemoveWhitelistPrefix(
    SenderRemoveWhitelistPrefixEvent event,
    Emitter<SenderState> emit,
  ) async {
    final updated = List<String>.from(state.senderWhitelist)..remove(event.prefix);
    try {
      final success = await repository.setSenderWhitelist(updated);
      if (success) {
        emit(state.copyWith(senderWhitelist: updated));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể xóa đầu số: ${e.toString()}',
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
