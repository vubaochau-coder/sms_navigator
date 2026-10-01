import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/device_setup_repository.dart';
import 'device_setup_event.dart';
import 'device_setup_state.dart';

class DeviceSetupBloc extends Bloc<DeviceSetupEvent, DeviceSetupState> {
  final DeviceSetupRepository repository;

  DeviceSetupBloc({required this.repository}) : super(const DeviceSetupState()) {
    on<DeviceSetupStarted>(_onStarted, transformer: restartable());
    on<DeviceSetupSmsPermissionRequested>(
      _onSmsPermissionRequested,
      transformer: droppable(),
    );
    on<DeviceSetupAppSettingsOpened>(_onAppSettingsOpened);
    on<DeviceSetupBatteryOptimizationRequested>(
      _onBatteryOptimizationRequested,
      transformer: droppable(),
    );
    on<DeviceSetupAutostartSettingsOpened>(
      _onAutostartSettingsOpened,
      transformer: droppable(),
    );
    on<DeviceSetupAutostartAcknowledged>(
      _onAutostartAcknowledged,
      transformer: droppable(),
    );
  }

  Future<void> _onStarted(
    DeviceSetupStarted event,
    Emitter<DeviceSetupState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final results = await Future.wait([
      repository.isSmsPermissionGranted(),
      repository.isSmsPermissionPermanentlyDenied(),
      repository.isBatteryOptimizationIgnored(),
      repository.getAggressiveRomInfo(),
      repository.isAutostartAcknowledged(),
    ]);
    final romInfo = results[3] as Map<String, dynamic>;
    emit(
      state.copyWith(
        isLoading: false,
        smsPermissionGranted: results[0] as bool,
        smsPermissionPermanentlyDenied: results[1] as bool,
        batteryUnrestricted: results[2] as bool,
        isAggressiveRom: romInfo['isAggressive'] == true,
        oemName: romInfo['oem']?.toString(),
        autostartAcknowledged: results[4] as bool,
      ),
    );
  }

  Future<void> _onSmsPermissionRequested(
    DeviceSetupSmsPermissionRequested event,
    Emitter<DeviceSetupState> emit,
  ) async {
    final granted = await repository.requestSmsPermission();
    final permanentlyDenied = granted
        ? false
        : await repository.isSmsPermissionPermanentlyDenied();
    emit(
      state.copyWith(
        smsPermissionGranted: granted,
        smsPermissionPermanentlyDenied: permanentlyDenied,
      ),
    );
  }

  Future<void> _onAppSettingsOpened(
    DeviceSetupAppSettingsOpened event,
    Emitter<DeviceSetupState> emit,
  ) async {
    await repository.openAppSettings();
  }

  Future<void> _onBatteryOptimizationRequested(
    DeviceSetupBatteryOptimizationRequested event,
    Emitter<DeviceSetupState> emit,
  ) async {
    final success = await repository.requestIgnoreBatteryOptimization();
    if (success) {
      final isIgnored = await repository.isBatteryOptimizationIgnored();
      emit(state.copyWith(batteryUnrestricted: isIgnored));
    }
  }

  Future<void> _onAutostartSettingsOpened(
    DeviceSetupAutostartSettingsOpened event,
    Emitter<DeviceSetupState> emit,
  ) async {
    await repository.openAutostartSettings();
    emit(state.copyWith(autostartScreenOpened: true));
  }

  Future<void> _onAutostartAcknowledged(
    DeviceSetupAutostartAcknowledged event,
    Emitter<DeviceSetupState> emit,
  ) async {
    final success = await repository.acknowledgeAutostart();
    if (success) {
      emit(state.copyWith(autostartAcknowledged: true));
    }
  }
}
