import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../data/repositories/sender_repository.dart';
import 'sender_event.dart';
import 'sender_state.dart';

class SenderBloc extends Bloc<SenderEvent, SenderState> {
  final SenderRepository repository;

  SenderBloc({required this.repository}) : super(const SenderState()) {
    on<SenderLoadStatusEvent>(_onLoadStatus, transformer: restartable());
    on<SenderCheckSmsPermissionEvent>(
      _onCheckSmsPermission,
      transformer: droppable(),
    );
    on<SenderToggleRelayEvent>(_onToggleRelay, transformer: droppable());
    on<SenderUpdateRelayModeEvent>(
      _onUpdateRelayMode,
      transformer: droppable(),
    );
    on<SenderAddWhitelistPrefixEvent>(
      _onAddWhitelistPrefix,
      transformer: droppable(),
    );
    on<SenderRemoveWhitelistPrefixEvent>(
      _onRemoveWhitelistPrefix,
      transformer: droppable(),
    );
    on<SenderRequestBatteryOptimizationEvent>(
      _onRequestBatteryOptimization,
      transformer: droppable(),
    );
    on<SenderUnpairEvent>(_onUnpair, transformer: droppable());
    on<SenderOtpDetectedEvent>(_onOtpDetected, transformer: sequential());

    repository.registerOtpListener((sender, otp) {
      add(SenderOtpDetectedEvent(sender, otp));
    });
  }

  Future<void> _onCheckSmsPermission(
    SenderCheckSmsPermissionEvent event,
    Emitter emit,
  ) async {
    try {
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        await Permission.sms.request();
      }
    } catch (_) {}
  }

  Future<void> _onLoadStatus(SenderLoadStatusEvent event, Emitter emit) async {
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

      emit(
        state.copyWith(
          isLoading: false,
          isRelayEnabled: isEnabled,
          relayMode: relayMode,
          senderWhitelist: senderWhitelist,
          isPaired: isPaired,
          pairId: pairId,
          deviceId: deviceId,
          isBatteryOptimizationIgnored: isBatteryIgnored,
          logs: logs,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lỗi tải trạng thái: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onToggleRelay(
    SenderToggleRelayEvent event,
    Emitter emit,
  ) async {
    try {
      final success = await repository.setRelayEnabled(event.isEnabled);
      if (success) {
        emit(state.copyWith(isRelayEnabled: event.isEnabled));
        ToastUtils.showSuccess(
          event.isEnabled
              ? 'Đã kích hoạt dịch vụ chuyển tiếp'
              : 'Đã tạm dừng dịch vụ chuyển tiếp',
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Không thể thay đổi trạng thái: ${e.toString()}',
        ),
      );
      ToastUtils.showError('Không thể thay đổi trạng thái chuyển tiếp');
    }
  }

  Future<void> _onUpdateRelayMode(
    SenderUpdateRelayModeEvent event,
    Emitter emit,
  ) async {
    try {
      final success = await repository.setRelayMode(event.relayMode);
      if (success) {
        emit(state.copyWith(relayMode: event.relayMode));
        ToastUtils.showInfo('Đã chuyển sang chế độ: ${event.relayMode}');
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage:
              'Không thể cập nhật chế độ chuyển tiếp: ${e.toString()}',
        ),
      );
      ToastUtils.showError('Không thể cập nhật chế độ chuyển tiếp');
    }
  }

  Future<void> _onAddWhitelistPrefix(
    SenderAddWhitelistPrefixEvent event,
    Emitter emit,
  ) async {
    final clean = event.prefix.trim();
    if (clean.isEmpty || state.senderWhitelist.contains(clean)) return;

    final updated = List<String>.from(state.senderWhitelist)..add(clean);
    try {
      final success = await repository.setSenderWhitelist(updated);
      if (success) {
        emit(state.copyWith(senderWhitelist: updated));
        ToastUtils.showSuccess('Đã thêm đầu số $clean vào bộ lọc');
      }
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Không thể thêm đầu số: ${e.toString()}'),
      );
      ToastUtils.showError('Không thể thêm đầu số');
    }
  }

  Future<void> _onRemoveWhitelistPrefix(
    SenderRemoveWhitelistPrefixEvent event,
    Emitter emit,
  ) async {
    final updated = List<String>.from(state.senderWhitelist)
      ..remove(event.prefix);
    try {
      final success = await repository.setSenderWhitelist(updated);
      if (success) {
        emit(state.copyWith(senderWhitelist: updated));
        ToastUtils.showInfo('Đã xóa đầu số ${event.prefix}');
      }
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Không thể xóa đầu số: ${e.toString()}'),
      );
      ToastUtils.showError('Không thể xóa đầu số');
    }
  }

  Future<void> _onRequestBatteryOptimization(
    SenderRequestBatteryOptimizationEvent event,
    Emitter emit,
  ) async {
    try {
      await repository.requestBatteryOptimization();
      final isIgnored = await repository.checkBatteryOptimization();
      emit(state.copyWith(isBatteryOptimizationIgnored: isIgnored));
    } catch (_) {}
  }

  Future<void> _onUnpair(SenderUnpairEvent event, Emitter emit) async {
    try {
      await repository.unpairDevice();
      emit(state.copyWith(isPaired: false, isRelayEnabled: false, pairId: ''));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi hủy ghép đôi: ${e.toString()}'));
    }
  }

  Future<void> _onOtpDetected(
    SenderOtpDetectedEvent event,
    Emitter emit,
  ) async {
    final updatedLogs = await repository.getRecentLogs();
    emit(
      state.copyWith(
        lastDetectedOtp: event.otp,
        lastDetectedSender: event.sender,
        logs: updatedLogs,
      ),
    );
  }
}
