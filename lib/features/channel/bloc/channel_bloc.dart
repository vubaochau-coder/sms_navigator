import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/channel_repository.dart';
import '../../../core/utils/toast_utils.dart';
import 'channel_event.dart';
import 'channel_state.dart';

export 'channel_event.dart';
export 'channel_state.dart';

/// Bloc danh sách kênh (cả Owner lẫn Member dùng chung màn này).
class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  ChannelBloc({required ChannelRepository repository})
    : _repository = repository,
      super(const ChannelState()) {
    on<ChannelLoadDataEvent>(_onLoadData, transformer: restartable());
    on<ChannelCreated>(_onCreated, transformer: droppable());
    on<DeviceRenamed>(_onRenamed, transformer: droppable());
  }

  final ChannelRepository _repository;

  Future<void> _onLoadData(
    ChannelLoadDataEvent event,
    Emitter<ChannelState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final channels = await _repository.listChannels();
      emit(
        state.copyWith(
          isLoading: false,
          ownedChannels: channels.where((c) => c.isOwner).toList(),
          joinedChannels: channels.where((c) => !c.isOwner).toList(),
        ),
      );
    } catch (error) {
      ToastUtils.showError(
        'Không tải được danh sách kênh. Kiểm tra kết nối và thử lại.',
      );
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage:
              'Không tải được danh sách kênh. Kiểm tra kết nối và thử lại.',
        ),
      );
    }
  }

  Future<void> _onCreated(
    ChannelCreated event,
    Emitter<ChannelState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.createChannel(event.name);
      final channels = await _repository.listChannels();
      emit(
        state.copyWith(
          isLoading: false,
          ownedChannels: channels.where((c) => c.isOwner).toList(),
          joinedChannels: channels.where((c) => !c.isOwner).toList(),
        ),
      );
    } catch (error) {
      ToastUtils.showError('Không tạo được kênh. Thử lại sau.');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không tạo được kênh. Thử lại sau.',
        ),
      );
    }
  }

  Future<void> _onRenamed(
    DeviceRenamed event,
    Emitter<ChannelState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.renameDevice(event.deviceName);
      emit(state.copyWith(isLoading: false));
    } catch (error) {
      ToastUtils.showError('Không đổi được tên thiết bị. Thử lại sau.');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không đổi được tên thiết bị. Thử lại sau.',
        ),
      );
    }
  }
}
