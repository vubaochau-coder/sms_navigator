import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/paired_device_item.dart';
import '../../data/services/pair_management_service.dart';

class PairedDevicesState {
  final bool isLoading;
  final String? errorMessage;
  final List<PairedDeviceItem> devices;
  final Set<String> togglingPairIds;

  const PairedDevicesState({
    this.isLoading = false,
    this.errorMessage,
    this.devices = const [],
    this.togglingPairIds = const {},
  });

  PairedDevicesState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<PairedDeviceItem>? devices,
    Set<String>? togglingPairIds,
  }) {
    return PairedDevicesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      devices: devices ?? this.devices,
      togglingPairIds: togglingPairIds ?? this.togglingPairIds,
    );
  }
}

class PairedDevicesCubit extends Cubit<PairedDevicesState> {
  final PairManagementService service;
  CancelToken? _cancelToken;

  PairedDevicesCubit(this.service) : super(const PairedDevicesState());

  @override
  Future<void> close() {
    _cancelToken?.cancel('PairedDevicesCubit closed');
    return super.close();
  }

  Future<void> loadReceivers({CancelToken? cancelToken}) async {
    _cancelToken?.cancel('Refresh receivers');
    final token = cancelToken ?? CancelToken();
    _cancelToken = token;

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await service.getPairedReceivers(cancelToken: token);
      emit(state.copyWith(isLoading: false, devices: items));
    } catch (e) {
      if (token.isCancelled) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách thiết bị nhận: $e',
      ));
    }
  }

  Future<void> loadSenders({CancelToken? cancelToken}) async {
    _cancelToken?.cancel('Refresh senders');
    final token = cancelToken ?? CancelToken();
    _cancelToken = token;

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await service.getPairedSenders(cancelToken: token);
      emit(state.copyWith(isLoading: false, devices: items));
    } catch (e) {
      if (token.isCancelled) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách thiết bị gửi: $e',
      ));
    }
  }

  Future<bool> toggleActive(String pairId, bool isActive) async {
    if (state.togglingPairIds.contains(pairId)) return false;

    final nextToggling = Set<String>.from(state.togglingPairIds)..add(pairId);
    emit(state.copyWith(togglingPairIds: nextToggling));

    final success = await service.togglePairActive(
      pairId: pairId,
      isActive: isActive,
    );

    final updatedToggling = Set<String>.from(state.togglingPairIds)..remove(pairId);

    if (success) {
      final updatedList = state.devices.map((e) {
        if (e.pairId == pairId) {
          return e.copyWith(isActive: isActive);
        }
        return e;
      }).toList();
      emit(state.copyWith(
        devices: updatedList,
        togglingPairIds: updatedToggling,
      ));
      return true;
    } else {
      emit(state.copyWith(togglingPairIds: updatedToggling));
      return false;
    }
  }

  Future<bool> revokePair(String pairId) async {
    final success = await service.revokePair(pairId);
    if (success) {
      final updatedList = state.devices.where((e) => e.pairId != pairId).toList();
      emit(state.copyWith(devices: updatedList));
      return true;
    }
    return false;
  }
}
