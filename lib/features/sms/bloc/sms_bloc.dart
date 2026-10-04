import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/repositories/sms_by_date_repository.dart';
import '../../../core/utils/toast_utils.dart';
import 'sms_event.dart';
import 'sms_state.dart';

export 'sms_event.dart';
export 'sms_state.dart';

/// Bloc màn SMS theo ngày:
/// - Tách biệt rõ ràng nghiệp vụ từng event:
///   + [SmsDateSelected]: kiểm tra date khác mới emit và add [SmsLoadDataEvent].
///   + [SmsLoadDataEvent]: thuần nhiệm vụ load data theo state hiện tại, áp dụng bloc concurrency (restartable) và CancelToken.
class SmsBloc extends Bloc<SmsEvent, SmsState> {
  SmsBloc({required SmsByDateRepository repository})
    : _repository = repository,
      super(SmsState(selectedDate: DateTime.now())) {
    on<SmsDateSelected>(_onDateSelected);
    on<SmsLoadDataEvent>(_onLoadData, transformer: restartable());
  }

  final SmsByDateRepository _repository;
  CancelToken? _cancelToken;

  void _onDateSelected(
    SmsDateSelected event,
    Emitter<SmsState> emit,
  ) {
    // Chỉ xử lý nếu ngày được chọn khác với ngày hiện tại trong state
    if (_isSameDay(state.selectedDate, event.date)) {
      return;
    }
    // Emit date trước khi add LoadDataEvent
    emit(state.copyWith(selectedDate: event.date));
    add(const SmsLoadDataEvent());
  }

  Future<void> _onLoadData(
    SmsLoadDataEvent event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Hủy request cũ nếu có request mới tới
    _cancelToken?.cancel('New load request started');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    try {
      final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
      final result = await _repository.fetchByDate(
        date: state.selectedDate,
        tzOffsetMinutes: tzOffset,
        cancelToken: cancelToken,
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
      // Bỏ qua nếu request bị hủy bởi cancelToken
      if (cancelToken.isCancelled || error is RequestCancelledException) {
        return;
      }

      ToastUtils.showError(
        'Không tải được tin nhắn SMS của ngày này. Kiểm tra kết nối và thử lại.',
        title: 'Lỗi tải tin nhắn',
      );
      emit(state.copyWith(isLoading: false));
    } finally {
      if (_cancelToken == cancelToken) {
        _cancelToken = null;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<void> close() {
    _cancelToken?.cancel('SmsBloc closed');
    return super.close();
  }
}
