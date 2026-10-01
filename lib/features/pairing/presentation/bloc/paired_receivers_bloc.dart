import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/pair_management_service.dart';
import 'paired_receivers_event.dart';
import 'paired_receivers_state.dart';

class PairedReceiversBloc
    extends Bloc<PairedReceiversEvent, PairedReceiversState> {
  final PairManagementService service;
  CancelToken? _cancelToken;

  PairedReceiversBloc(this.service) : super(const PairedReceiversState()) {
    on<PairedReceiversLoadEvent>(_onLoadReceivers);
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
}
