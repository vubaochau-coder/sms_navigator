import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/channel_repository.dart';
import '../../../core/services/device_storage_service.dart';
import '../../../core/services/native_relay_service.dart';
import '../../../core/ui/dialog_utils.dart';
import '../../../core/ui/toast_utils.dart';
import 'device_profile_state.dart';
import '../../../core/l10n/app_l10n.dart';

class DeviceProfileCubit extends Cubit<DeviceProfileState> {
  final DeviceStorageService _deviceStorage;
  final ChannelRepository _channelRepository;
  final NativeRelayService? _nativeRelayService;

  DeviceProfileCubit({
    required DeviceStorageService deviceStorage,
    required ChannelRepository channelRepository,
    NativeRelayService? nativeRelayService,
  })  : _deviceStorage = deviceStorage,
        _channelRepository = channelRepository,
        _nativeRelayService = nativeRelayService,
        super(const DeviceProfileState());

  Future<void> loadDeviceProfile() async {
    emit(state.copyWith(isLoading: true));
    try {
      final id = await _deviceStorage.getDeviceId() ?? '';
      final name = await _deviceStorage.getDeviceName();
      var resolvedName = (name != null && name.trim().isNotEmpty) ? name.trim() : '';

      if (resolvedName.isEmpty || resolvedName == AppL10n.current.splashDefaultDeviceName) {
        try {
          final nativeName = await _nativeRelayService?.getDeviceName();
          if (nativeName != null && nativeName.trim().isNotEmpty) {
            resolvedName = nativeName.trim();
            await _deviceStorage.saveDeviceName(resolvedName);
          }
        } catch (_) {}
      }

      emit(state.copyWith(
        isLoading: false,
        deviceId: id,
        deviceName: (resolvedName.isNotEmpty)
            ? resolvedName
            : AppL10n.current.splashDefaultDeviceName,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<bool> renameDevice(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    emit(state.copyWith(isRenaming: true));
    DialogUtils.showLoading(message: AppL10n.current.deviceRenameLoading);
    try {
      await _channelRepository.renameDevice(trimmed);
      await _deviceStorage.saveDeviceName(trimmed);
      emit(state.copyWith(isRenaming: false, deviceName: trimmed));
      ToastUtils.showSuccess(AppL10n.current.deviceRenameSuccess);
      return true;
    } catch (e) {
      emit(state.copyWith(isRenaming: false));
      ToastUtils.showError(AppL10n.current.deviceRenameFailed);
      return false;
    } finally {
      DialogUtils.closeLoading();
    }
  }

  /// Xóa toàn bộ thông tin định danh, token và cấu hình thiết bị trên máy.
  Future<bool> clearDeviceData() async {
    DialogUtils.showLoading(message: AppL10n.current.deviceResetLoading);
    try {
      await _deviceStorage.clearAll();
      emit(state.copyWith(
        deviceId: '',
        deviceName: '',
      ));
      ToastUtils.showSuccess(AppL10n.current.deviceResetSuccess);
      return true;
    } catch (e) {
      ToastUtils.showError(AppL10n.current.deviceResetFailed);
      return false;
    } finally {
      DialogUtils.closeLoading();
    }
  }
}
