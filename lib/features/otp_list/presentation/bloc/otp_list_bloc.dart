import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../data/repositories/otp_list_repository.dart';
import 'otp_list_event.dart';
import 'otp_list_state.dart';

class OtpListBloc extends Bloc<OtpListEvent, OtpListState> {
  final OtpListRepository repository;
  CancelToken? _cancelToken;

  OtpListBloc({required this.repository})
      : super(OtpListState(selectedDate: DateTime.now())) {
    on<OtpListLoadEvent>(_onLoadOtpList, transformer: restartable());
    on<OtpListChangeDateEvent>(_onChangeDate, transformer: restartable());
    on<OtpListToggleGroupEvent>(_onToggleGroup, transformer: droppable());
  }

  Future<void> _onLoadOtpList(
    OtpListLoadEvent event,
    Emitter<OtpListState> emit,
  ) async {
    _cancelToken?.cancel('Đã chuyển sang ngày khác.');
    final currentCancelToken = CancelToken();
    _cancelToken = currentCancelToken;

    emit(state.copyWith(
      isLoading: true,
      selectedDate: event.date,
      errorMessage: null,
    ));
    try {
      final items = await repository.getOtpListForDate(
        event.date,
        pairId: event.pairId,
        cancelToken: currentCancelToken,
      );
      if (emit.isDone) return;
      emit(state.copyWith(
        isLoading: false,
        items: items,
        selectedDate: event.date,
      ));
    } on RequestCancelledException {
      // Yêu cầu bị hủy có chủ đích khi chuyển ngày nhanh -> bỏ qua, không báo lỗi
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải danh sách OTP: ${e.toString()}',
      ));
    }
  }

  Future<void> _onChangeDate(
    OtpListChangeDateEvent event,
    Emitter<OtpListState> emit,
  ) async {
    add(OtpListLoadEvent(date: event.selectedDate));
  }

  void _onToggleGroup(
    OtpListToggleGroupEvent event,
    Emitter<OtpListState> emit,
  ) {
    emit(state.copyWith(isGroupingByDevice: !state.isGroupingByDevice));
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('Bloc closed');
    return super.close();
  }
}
