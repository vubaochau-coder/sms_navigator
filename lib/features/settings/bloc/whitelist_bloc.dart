import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/toast_utils.dart';
import '../../../core/models/whitelist_config_model.dart';
import '../../../core/repositories/whitelist_repository.dart';
import 'whitelist_event.dart';
import 'whitelist_state.dart';

class WhitelistBloc extends Bloc<WhitelistEvent, WhitelistState> {
  final WhitelistRepository repository;

  WhitelistBloc({required this.repository}) : super(const WhitelistState()) {
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
      final config = await repository.getWhitelist();
      try {
        logs = await repository.getRecentLogs();
      } catch (_) {
        // Log chẩn đoán — lỗi im lặng, không phá màn hình
      }
      emit(state.copyWith(isLoading: false, config: config, recentLogs: logs));
    } catch (e) {
      ToastUtils.showError('Không thể đọc cấu hình white-list: $e');
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
      ToastUtils.showError('Địa chỉ không được để trống');
      return;
    }

    final isDuplicate = state.config.entries.any(
      (entry) => entry.address == address,
    );
    if (isDuplicate) {
      ToastUtils.showError('Địa chỉ "$address" đã có trong danh sách');
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

  /// Lưu xuống native trước khi phát state mới — native là nguồn chân lý.
  Future<void> _persist(
    WhitelistConfigModel updated,
    Emitter<WhitelistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final saved = await repository.saveWhitelist(updated);
    if (!saved) {
      ToastUtils.showError('Không thể lưu cấu hình white-list');
      emit(state.copyWith(isLoading: false));
      return;
    }
    emit(state.copyWith(isLoading: false, config: updated));
  }
}
