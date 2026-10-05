import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/channel_repository.dart';
import '../../../core/services/device_storage_service.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/utils/toast_utils.dart';
import 'device_profile_state.dart';

class DeviceProfileCubit extends Cubit<DeviceProfileState> {
  final DeviceStorageService _deviceStorage;
  final ChannelRepository _channelRepository;

  DeviceProfileCubit({
    required DeviceStorageService deviceStorage,
    required ChannelRepository channelRepository,
  })  : _deviceStorage = deviceStorage,
        _channelRepository = channelRepository,
        super(const DeviceProfileState());

  Future<void> loadDeviceProfile() async {
    emit(state.copyWith(isLoading: true));
    try {
      final id = await _deviceStorage.getDeviceId() ?? '';
      final name = await _deviceStorage.getDeviceName();
      emit(state.copyWith(
        isLoading: false,
        deviceId: id,
        deviceName: (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : 'Thiết bị của tôi',
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<bool> renameDevice(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    emit(state.copyWith(isRenaming: true));
    DialogUtils.showLoading(message: 'Đang cập nhật tên thiết bị...');
    try {
      await _channelRepository.renameDevice(trimmed);
      await _deviceStorage.saveDeviceName(trimmed);
      emit(state.copyWith(isRenaming: false, deviceName: trimmed));
      ToastUtils.showSuccess('Đã cập nhật tên thiết bị');
      return true;
    } catch (e) {
      emit(state.copyWith(isRenaming: false));
      ToastUtils.showError('Không đổi được tên thiết bị. Thử lại sau.');
      return false;
    } finally {
      DialogUtils.closeLoading();
    }
  }
}
