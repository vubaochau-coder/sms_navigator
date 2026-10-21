import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/models/whitelist_config_model.dart';
import '../../../core/repositories/channel_repository.dart';
import '../../../core/repositories/whitelist_repository.dart';
import '../../../core/services/channel_key_store.dart';
import '../../../core/ui/toast_utils.dart';
import 'whitelist_event.dart';
import 'whitelist_state.dart';
import '../../../core/l10n/app_l10n.dart';

class WhitelistBloc extends Bloc<WhitelistEvent, WhitelistState> {
  final String channelId;
  final WhitelistRepository repository;
  final ChannelRepository channelRepository;
  final ChannelKeyStore keyStore;

  WhitelistBloc({
    required this.channelId,
    required this.repository,
    required this.channelRepository,
    required this.keyStore,
  }) : super(const WhitelistState()) {
    on<WhitelistStarted>(_onStarted);
    on<WhitelistModeChanged>(_onModeChanged);
    on<WhitelistEntryAdded>(_onEntryAdded);
    on<WhitelistAllowOtpToggled>(_onAllowOtpToggled);
    on<WhitelistEntryRemoved>(_onEntryRemoved);
    on<WhitelistLogsRefreshed>(_onLogsRefreshed);
  }

  Future<void> _onStarted(
    WhitelistStarted event,
    Emitter<WhitelistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    List<Map<String, dynamic>> logs = const [];
    try {
      final localConfig = await repository.getWhitelist(channelId);
      try {
        logs = await repository.getRecentLogs();
      } catch (_) {
        // Log chẩn đoán — lỗi im lặng, không phá màn hình
      }
      emit(state.copyWith(isLoading: false, config: localConfig, recentLogs: logs));

      // Reconcile nền với server (v2.2): nếu online và server có version mới hơn -> sync xuống
      try {
        final detail = await channelRepository.getChannelDetail(channelId);
        final blob = detail.whitelist;
        if (blob != null && blob.whitelistVersion > localConfig.version) {
          final channelKey = await keyStore.getChannelKey(
            channelId: channelId,
            epoch: blob.keyEpoch,
          );
          if (channelKey != null && channelKey.isNotEmpty) {
            final synced = await repository.syncWhitelistFromServer(
              channelId: channelId,
              keyEpoch: blob.keyEpoch,
              channelKeyBase64: channelKey,
              blob: blob,
            );
            if (synced != null) {
              emit(state.copyWith(config: synced));
            }
          }
        }
      } catch (_) {
        // Lỗi mạng nền khi reconcile — dùng cache local hiện có
      }
    } catch (e) {
      ToastUtils.showError(AppL10n.current.whitelistLoadFailed);
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onLogsRefreshed(
    WhitelistLogsRefreshed event,
    Emitter<WhitelistState> emit,
  ) async {
    try {
      final logs = await repository.getRecentLogs();
      emit(state.copyWith(recentLogs: logs));
    } catch (_) {
      // Log chẩn đoán — lỗi im lặng, không phá UI
    }
  }

  Future<void> _onModeChanged(
    WhitelistModeChanged event,
    Emitter<WhitelistState> emit,
  ) async {
    if (event.mode == state.config.mode) return;
    final updated = state.config.copyWith(mode: event.mode);
    await _persist(updated, emit);
  }

  Future<void> _onEntryAdded(
    WhitelistEntryAdded event,
    Emitter<WhitelistState> emit,
  ) async {
    final address = event.address.trim();
    if (address.isEmpty) {
      ToastUtils.showError(AppL10n.current.whitelistEmptyAddressError);
      return;
    }

    final isDuplicate = state.config.entries.any(
      (entry) => entry.address == address,
    );
    if (isDuplicate) {
      ToastUtils.showError(AppL10n.current.whitelistDuplicateError(address));
      return;
    }

    final updated = state.config.copyWith(
      entries: [
        ...state.config.entries,
        WhitelistEntryModel(address: address, allowOtp: event.allowOtp),
      ],
    );
    await _persist(updated, emit);
  }

  Future<void> _onAllowOtpToggled(
    WhitelistAllowOtpToggled event,
    Emitter<WhitelistState> emit,
  ) async {
    final updated = state.config.copyWith(
      entries: state.config.entries
          .map(
            (entry) => entry.address == event.entry.address
                ? entry.copyWith(allowOtp: !entry.allowOtp)
                : entry,
          )
          .toList(),
    );
    await _persist(updated, emit);
  }

  Future<void> _onEntryRemoved(
    WhitelistEntryRemoved event,
    Emitter<WhitelistState> emit,
  ) async {
    final updated = state.config.copyWith(
      entries: state.config.entries
          .where(
            (entry) => entry.address != event.entry.address,
          )
          .toList(),
    );
    await _persist(updated, emit);
  }

  // Server là nguồn chân lý duy nhất (v2.2): PUT server thành công trước khi ghi cache native.
  Future<void> _persist(
    WhitelistConfigModel updated,
    Emitter<WhitelistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final detail = await channelRepository.getChannelDetail(channelId);
      final keyEpoch = detail.currentEpoch;
      final channelKey = await keyStore.getChannelKey(
        channelId: channelId,
        epoch: keyEpoch,
      );

      if (channelKey == null || channelKey.isEmpty) {
        ToastUtils.showError(AppL10n.current.whitelistMissingChannelKey);
        emit(state.copyWith(isLoading: false));
        return;
      }

      final serverVersion = detail.whitelist?.whitelistVersion ?? 0;
      final baseVersion = state.config.version > serverVersion ? state.config.version : serverVersion;
      final nextVersion = baseVersion + 1;
      final configToSave = updated.copyWith(version: nextVersion);

      final saved = await repository.saveWhitelist(
        channelId: channelId,
        config: configToSave,
        keyEpoch: keyEpoch,
        channelKeyBase64: channelKey,
      );

      if (!saved) {
        ToastUtils.showError(AppL10n.current.whitelistSaveFailed);
        emit(state.copyWith(isLoading: false));
        return;
      }

      emit(state.copyWith(isLoading: false, config: configToSave));
    } on ApiException catch (e) {
      if (e.statusCode == 409 || e.errorCode == 'STALE_WHITELIST') {
        ToastUtils.showError(AppL10n.current.whitelistConflict);
      } else {
        ToastUtils.showError(AppL10n.current.whitelistSaveRequiresNetwork(e.message));
      }
      emit(state.copyWith(isLoading: false));
    } on NetworkException catch (_) {
      ToastUtils.showError(AppL10n.current.whitelistSaveOffline);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      ToastUtils.showError(AppL10n.current.whitelistSaveFailed);
      emit(state.copyWith(isLoading: false));
    }
  }
}
