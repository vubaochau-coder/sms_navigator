import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/pair_management_service.dart';
import 'paired_senders_event.dart';
import 'paired_senders_state.dart';

class PairedSendersBloc extends Bloc<PairedSendersEvent, PairedSendersState> {
  final PairManagementService service;
  CancelToken? _cancelToken;

  PairedSendersBloc(this.service) : super(const PairedSendersState()) {
    on<PairedSendersLoadEvent>(_onLoadSenders);
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('PairedSendersBloc closed');
    return super.close();
  }

  Future<void> _onLoadSenders(
    PairedSendersLoadEvent event,
    Emitter<PairedSendersState> emit,
  ) async {
    _cancelToken?.cancel('Refresh senders');
    final token = CancelToken();
    _cancelToken = token;

    if (state.devices.isEmpty) {
      emit(state.copyWith(isLoading: true, clearError: true));
    } else {
      emit(state.copyWith(clearError: true));
    }

    try {
      final items = await service.getPairedSenders(cancelToken: token);
      emit(state.copyWith(isLoading: false, devices: items));
    } catch (e) {
      if (token.isCancelled) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải danh sách thiết bị gửi: $e',
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }
}
