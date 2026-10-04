import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/sms_by_date_repository.dart';
import '../../../core/utils/toast_utils.dart';
import 'sms_event.dart';
import 'sms_state.dart';

export 'sms_event.dart';
export 'sms_state.dart';

/// Bloc màn SMS theo ngày: mỗi lần mở là một lần fetch (không local store).
/// Lỗi tải tin nhắn được bắn trực tiếp qua ToastUtils (không phụ thuộc BuildContext).
class SmsBloc extends Bloc<SmsEvent, SmsState> {
  SmsBloc({required SmsByDateRepository repository})
    : _repository = repository,
      super(SmsState(selectedDate: DateTime.now())) {
    on<SmsDateSelected>(_onDateSelected, transformer: droppable());
    on<SmsRefreshed>(_onRefreshed, transformer: droppable());
  }

  final SmsByDateRepository _repository;

  Future<void> _onDateSelected(
    SmsDateSelected event,
    Emitter<SmsState> emit,
  ) async {
    await _load(event.date, emit);
  }

  Future<void> _onRefreshed(
    SmsRefreshed event,
    Emitter<SmsState> emit,
  ) async {
    await _load(state.selectedDate, emit);
  }

  Future<void> _load(DateTime date, Emitter<SmsState> emit) async {
    emit(
      state.copyWith(
        selectedDate: date,
        isLoading: true,
      ),
    );
    try {
      // tz_offset của máy theo phút east-of-UTC (đúng contract §6.3)
      final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
      final result = await _repository.fetchByDate(
        date: date,
        tzOffsetMinutes: tzOffset,
      );
      emit(
        state.copyWith(
          isLoading: false,
          messages: result.messages,
          truncated: result.truncated,
          hasFetchedOnce: true,
        ),
      );
    } catch (error) {
      ToastUtils.showError(
        'Không tải được tin nhắn SMS của ngày này. Kiểm tra kết nối và thử lại.',
        title: 'Lỗi tải tin nhắn',
      );
      emit(
        state.copyWith(
          isLoading: false,
        ),
      );
    }
  }
}

// Backward compatibility typedefs
typedef SmsByDateBloc = SmsBloc;
typedef OtpByDateBloc = SmsBloc;
