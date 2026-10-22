import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/channel_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/repositories/channel_repository.dart';
import '../../../core/repositories/join_channel_repository.dart';
import '../../../core/services/startup_reconcile_service.dart';
import '../../../core/usecases/sync_owner_relay_channel_use_case.dart';
import '../../../core/ui/toast_utils.dart';
import 'channel_event.dart';
import 'channel_state.dart';
import '../../../core/l10n/app_l10n.dart';

export 'channel_event.dart';
export 'channel_state.dart';

/// Bloc danh sách kênh (cả Owner lẫn Member dùng chung màn này).
class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  ChannelBloc({
    required ChannelRepository repository,
    JoinChannelRepository? joinRepository,
    StartupReconcileService? reconcileService,
    SyncOwnerRelayChannelUseCase? syncUseCase,
  }) : _repository = repository,
       _joinRepository = joinRepository,
       _reconcileService = reconcileService,
       _syncUseCase = syncUseCase,
       super(const ChannelState()) {
    on<ChannelLoadDataEvent>(_onLoadData, transformer: restartable());
    on<ChannelCreated>(_onCreated, transformer: droppable());
    on<DeviceRenamed>(_onRenamed, transformer: droppable());
    on<ChannelPendingJoinCancelled>(
      _onCancelPendingJoin,
      transformer: droppable(),
    );
  }

  final ChannelRepository _repository;
  final JoinChannelRepository? _joinRepository;
  final StartupReconcileService? _reconcileService;
  final SyncOwnerRelayChannelUseCase? _syncUseCase;

  Future<void> _onLoadData(
    ChannelLoadDataEvent event,
    Emitter<ChannelState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final channelsFuture = _repository.listChannelsWithWhitelist();
      bool requestsFailed = false;
      final requestsFuture = _joinRepository != null
          ? _joinRepository.listMyRequests().catchError((_) {
              requestsFailed = true;
              return <PairingRequestModel>[];
            })
          : Future.value(<PairingRequestModel>[]);

      final results = await Future.wait([channelsFuture, requestsFuture]);
      final channels = results[0] as List<ChannelModel>;
      final requests = results[1] as List<PairingRequestModel>;
      final pendingRequests = requestsFailed
          ? state.pendingJoinRequests
          : requests.where((r) => r.isPending).toList();

      emit(
        state.copyWith(
          isLoading: false,
          ownedChannels: channels.where((c) => c.isOwner).toList(),
          joinedChannels: channels.where((c) => !c.isOwner).toList(),
          pendingJoinRequests: pendingRequests,
        ),
      );
      _reconcileService?.reconcile().catchError((_) => null);
      _syncUseCase?.call().catchError((_) => false);
    } catch (error) {
      ToastUtils.showError(
        AppL10n.current.channelLoadFailed,
      );
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage:
              AppL10n.current.channelLoadFailed,
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
      final channels = await _repository.listChannelsWithWhitelist();
      emit(
        state.copyWith(
          isLoading: false,
          ownedChannels: channels.where((c) => c.isOwner).toList(),
          joinedChannels: channels.where((c) => !c.isOwner).toList(),
        ),
      );
      _syncUseCase?.call().catchError((_) => false);
    } catch (error) {
      ToastUtils.showError(AppL10n.current.channelCreateFailed);
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: AppL10n.current.channelCreateFailed,
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
      ToastUtils.showError(AppL10n.current.deviceRenameFailed);
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: AppL10n.current.deviceRenameFailed,
        ),
      );
    }
  }

  Future<void> _onCancelPendingJoin(
    ChannelPendingJoinCancelled event,
    Emitter<ChannelState> emit,
  ) async {
    if (_joinRepository == null) return;
    try {
      await _joinRepository.cancelRequest(event.requestId);
      final updatedPending = state.pendingJoinRequests
          .where((r) => r.requestId != event.requestId)
          .toList();
      emit(state.copyWith(pendingJoinRequests: updatedPending));
      ToastUtils.showSuccess(
        event.successMessage ?? AppL10n.current.channelCancelRequestSuccess,
      );
    } catch (error) {
      ToastUtils.showError(
        event.errorMessage ?? AppL10n.current.channelCancelRequestFailed,
      );
    }
  }
}
