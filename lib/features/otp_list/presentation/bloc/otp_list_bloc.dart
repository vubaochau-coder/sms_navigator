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
    on<OtpListSelectDateEvent>(_onSelectDate, transformer: restartable());
    on<OtpListChangeFormatEvent>(_onChangeFormat, transformer: droppable());
    on<OtpListChangeFocusedDayEvent>(
      _onChangeFocusedDay,
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
    emit(
      state.copyWith(
        selectedDate: event.selectedDate,
        focusedDate: event.selectedDate,
      ),
    );
    add(const OtpListLoadEvent());
  }

  void _onToggleGroup(OtpListToggleGroupEvent event, Emitter emit) {
    emit(state.copyWith(isGroupingByDevice: !state.isGroupingByDevice));
  }

  Future<void> _onSelectDate(OtpListSelectDateEvent event, Emitter emit) async {
    emit(
      state.copyWith(
        selectedDate: event.selectedDay,
        focusedDate: event.focusedDay,
      ),
    );
    add(const OtpListLoadEvent());
  }

  void _onChangeFormat(OtpListChangeFormatEvent event, Emitter emit) {
    emit(state.copyWith(calendarFormat: event.format));
  }

  void _onChangeFocusedDay(OtpListChangeFocusedDayEvent event, Emitter emit) {
    emit(state.copyWith(focusedDate: event.focusedDay));
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('Bloc closed');
    return super.close();
  }
}
