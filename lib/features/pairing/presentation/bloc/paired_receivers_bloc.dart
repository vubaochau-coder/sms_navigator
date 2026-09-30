import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../data/services/pair_management_service.dart';
import 'paired_receivers_event.dart';
import 'paired_receivers_state.dart';

class PairedReceiversBloc
    extends Bloc<PairedReceiversEvent, PairedReceiversState> {
  final PairManagementService service;
  CancelToken? _cancelToken;

  PairedReceiversBloc(this.service) : super(const PairedReceiversState()) {
    on<PairedReceiversLoadEvent>(_onLoadReceivers);
    on<PairedReceiversToggleActiveEvent>(_onToggleActive);
    on<PairedReceiversRevokeEvent>(_onRevokePair);
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('PairedReceiversBloc closed');
    return super.close();
  }

  Future<void> _onLoadReceivers(
    PairedReceiversLoadEvent event,
    Emitter<PairedReceiversState> emit,
  ) async {
    _cancelToken?.cancel('Refresh receivers');
    final token = CancelToken();
    _cancelToken = token;

    if (state.devices.isEmpty) {
      emit(state.copyWith(isLoading: true, clearError: true));
    } else {
      emit(state.copyWith(clearError: true));
    }

    try {
      final items = await service.getPairedReceivers(cancelToken: token);
      emit(state.copyWith(isLoading: false, devices: items));
    } catch (e) {
      if (token.isCancelled) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải danh sách thiết bị nhận: $e',
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onToggleActive(
    PairedReceiversToggleActiveEvent event,
    Emitter<PairedReceiversState> emit,
  ) async {
    if (state.togglingPairIds.contains(event.pairId)) return;

    final nextToggling = Set<String>.from(state.togglingPairIds)
      ..add(event.pairId);
    emit(state.copyWith(togglingPairIds: nextToggling));

    final success = await service.togglePairActive(
      pairId: event.pairId,
      isActive: event.isActive,
    );

    final updatedToggling = Set<String>.from(state.togglingPairIds)
      ..remove(event.pairId);

    if (success) {
      final updatedList = state.devices.map((e) {
        if (e.pairId == event.pairId) {
          return e.copyWith(isActive: event.isActive);
        }
        return e;
      }).toList();
      emit(
        state.copyWith(devices: updatedList, togglingPairIds: updatedToggling),
      );
      ToastUtils.showSuccess(
        event.isActive
            ? 'Đã bật chuyển tiếp tới ${event.displayName ?? 'thiết bị'}'
            : 'Đã tạm dừng chuyển tiếp tới ${event.displayName ?? 'thiết bị'}',
      );
    } else {
      emit(state.copyWith(togglingPairIds: updatedToggling));
      ToastUtils.showError('Không thể cập nhật trạng thái. Vui lòng thử lại!');
    }
  }

  Future<void> _onRevokePair(
    PairedReceiversRevokeEvent event,
    Emitter<PairedReceiversState> emit,
  ) async {
    final success = await service.revokePair(event.pairId);
    if (success) {
      final updatedList = state.devices
          .where((e) => e.pairId != event.pairId)
          .toList();
      emit(state.copyWith(devices: updatedList));
      ToastUtils.showSuccess('Đã hủy kết nối thành công');
    } else {
      ToastUtils.showError('Không thể hủy kết nối. Vui lòng thử lại!');
    }
  }
}
