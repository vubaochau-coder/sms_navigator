import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/date_time_utils.dart';
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
    on<OtpListChangeFormatEvent>(_onChangeFormat, transformer: droppable());
    on<OtpListChangeDirectionFilterEvent>(
      _onChangeDirectionFilter,
      transformer: droppable(),
    );
  }

  Future<void> _onLoadOtpList(OtpListLoadEvent event, Emitter emit) async {
    _cancelToken?.cancel('Đã chuyển sang ngày khác.');
    final currentCancelToken = CancelToken();
    _cancelToken = currentCancelToken;

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );
    try {
      final items = await repository.getOtpListForDate(
        state.selectedDate,
        cancelToken: currentCancelToken,
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          isLoading: false,
          items: items,
        ),
      );
    } on RequestCancelledException {
      // Yêu cầu bị hủy có chủ đích khi chuyển ngày nhanh -> bỏ qua, không báo lỗi
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lỗi tải danh sách OTP: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onChangeDate(OtpListChangeDateEvent event, Emitter emit) async {
    final targetSelectedDate = event.selectedDate;
    final targetFocusedDate = event.focusedDate ?? event.selectedDate;

    final isSelectedChanged = targetSelectedDate != null &&
        !DateTimeUtils.isSameDay(state.selectedDate, targetSelectedDate);

    final isFocusedChanged = targetFocusedDate != null &&
        !DateTimeUtils.isSameDay(state.focusedDate, targetFocusedDate);

    if (!isSelectedChanged && !isFocusedChanged) {
      return;
    }

    emit(
      state.copyWith(
        selectedDate:
            isSelectedChanged ? targetSelectedDate : state.selectedDate,
        focusedDate:
            isFocusedChanged ? targetFocusedDate : state.focusedDate,
      ),
    );

    if (isSelectedChanged) {
      add(const OtpListLoadEvent());
    }
  }

  void _onToggleGroup(OtpListToggleGroupEvent event, Emitter emit) {
    emit(state.copyWith(isGroupingByDevice: !state.isGroupingByDevice));
  }

  void _onChangeFormat(OtpListChangeFormatEvent event, Emitter emit) {
    emit(state.copyWith(calendarFormat: event.format));
  }

  void _onChangeDirectionFilter(
    OtpListChangeDirectionFilterEvent event,
    Emitter emit,
  ) {
    if (state.directionFilter == event.filter) return;
    emit(state.copyWith(directionFilter: event.filter));
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('Bloc closed');
    return super.close();
  }
}
