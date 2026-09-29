import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/otp_list_repository.dart';
import 'otp_list_event.dart';
import 'otp_list_state.dart';

class OtpListBloc extends Bloc<OtpListEvent, OtpListState> {
  final OtpListRepository repository;

  OtpListBloc({required this.repository})
      : super(OtpListState(selectedDate: DateTime.now())) {
    on<OtpListLoadEvent>(_onLoadOtpList);
    on<OtpListChangeDateEvent>(_onChangeDate);
    on<OtpListToggleGroupEvent>(_onToggleGroup);
  }

  Future<void> _onLoadOtpList(
    OtpListLoadEvent event,
    Emitter<OtpListState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      selectedDate: event.date,
      errorMessage: null,
    ));
    try {
      final items = await repository.getOtpListForDate(event.date, pairId: event.pairId);
      emit(state.copyWith(
        isLoading: false,
        items: items,
        selectedDate: event.date,
      ));
    } catch (e) {
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
}
