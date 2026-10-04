import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/channel_model.dart';
import '../../data/repositories/channel_repository.dart';

/// Trạng thái màn danh sách kênh: 2 nhóm "Kênh của bạn" (Owner) / "Kênh bạn
/// tham gia" (Member) — nguồn `GET /channels`, nhóm theo `role` (2.1).
class ChannelListState extends Equatable {
  final bool isLoading;
  final List<ChannelModel> ownedChannels;
  final List<ChannelModel> joinedChannels;
  final String? errorMessage;

  const ChannelListState({
    this.isLoading = false,
    this.ownedChannels = const [],
    this.joinedChannels = const [],
    this.errorMessage,
  });

  bool get isEmpty =>
      !isLoading &&
      errorMessage == null &&
      ownedChannels.isEmpty &&
      joinedChannels.isEmpty;

  ChannelListState copyWith({
    bool? isLoading,
    List<ChannelModel>? ownedChannels,
    List<ChannelModel>? joinedChannels,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChannelListState(
      isLoading: isLoading ?? this.isLoading,
      ownedChannels: ownedChannels ?? this.ownedChannels,
      joinedChannels: joinedChannels ?? this.joinedChannels,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, ownedChannels, joinedChannels, errorMessage];
}

abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object?> get props => [];
}

/// Load danh sách kênh khi mở tab / pull-to-refresh (2.1).
class ChannelListLoaded extends ChannelEvent {
  const ChannelListLoaded();
}

/// Tạo kênh (2.2) — xuất hiện ở nhóm "Kênh của bạn".
class ChannelCreated extends ChannelEvent {
  final String name;

  const ChannelCreated(this.name);

  @override
  List<Object?> get props => [name];
}

/// Đổi tên thiết bị (1.2) — server tự fan-out mọi kênh + request chờ duyệt.
class DeviceRenamed extends ChannelEvent {
  final String deviceName;

  const DeviceRenamed(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

/// Bloc danh sách kênh (cả Owner lẫn Member dùng chung màn này).
class ChannelBloc extends Bloc<ChannelEvent, ChannelListState> {
  ChannelBloc({required ChannelRepository repository})
    : _repository = repository,
      super(const ChannelListState()) {
    on<ChannelListLoaded>(_onListLoaded, transformer: restartable());
    on<ChannelCreated>(_onCreated, transformer: droppable());
    on<DeviceRenamed>(_onRenamed, transformer: droppable());
  }

  final ChannelRepository _repository;

  Future<void> _onListLoaded(
    ChannelListLoaded event,
    Emitter<ChannelListState> emit,
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
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không tải được danh sách kênh. Kiểm tra kết nối và thử lại.',
        ),
      );
    }
  }

  Future<void> _onCreated(
    ChannelCreated event,
    Emitter<ChannelListState> emit,
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
    Emitter<ChannelListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.renameDevice(event.deviceName);
      emit(state.copyWith(isLoading: false));
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không đổi được tên thiết bị. Thử lại sau.',
        ),
      );
    }
  }
}
