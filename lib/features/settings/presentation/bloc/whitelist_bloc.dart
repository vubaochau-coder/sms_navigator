import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../sender/data/models/whitelist_config_model.dart';
import '../../data/repositories/whitelist_repository.dart';
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
  }

  Future<void> _onStarted(
    WhitelistStarted event,
    Emitter<WhitelistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    try {
      final config = await repository.getWhitelist();
      emit(state.copyWith(isLoading: false, config: config));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể đọc cấu hình white-list: $e',
        ),
      );
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
      emit(
        state.copyWith(
          errorMessage: 'Địa chỉ không được để trống',
          clearSuccess: true,
        ),
      );
      return;
    }

    final isDuplicate = state.config.entries.any(
      (entry) => entry.address.toLowerCase() == address.toLowerCase(),
    );
    if (isDuplicate) {
      emit(
        state.copyWith(
          errorMessage: 'Địa chỉ "$address" đã có trong danh sách',
          clearSuccess: true,
        ),
      );
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
            (entry) => entry.address.toLowerCase() == event.entry.address.toLowerCase()
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
            (entry) => entry.address.toLowerCase() != event.entry.address.toLowerCase(),
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
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    final saved = await repository.saveWhitelist(updated);
    if (!saved) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể lưu cấu hình white-list',
          clearSuccess: true,
        ),
      );
      return;
    }
    emit(state.copyWith(isLoading: false, config: updated));
  }
}
