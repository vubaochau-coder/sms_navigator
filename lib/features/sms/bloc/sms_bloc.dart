import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/models/channel_event.dart';
import '../../../core/repositories/sms_by_date_repository.dart';
import '../../../core/ui/toast_utils.dart';
import 'sms_event.dart';
import 'sms_state.dart';
import '../../../core/l10n/app_l10n.dart';

export 'sms_event.dart';
export 'sms_state.dart';

/// Bloc màn SMS theo ngày:
/// - Tách biệt rõ ràng nghiệp vụ từng event:
///   + [SmsDateSelected]: kiểm tra date khác mới emit và add [SmsLoadDataEvent].
///   + [SmsLoadDataEvent]: thuần nhiệm vụ load data theo state hiện tại, áp dụng bloc concurrency (restartable) và CancelToken.
///   + [SmsChannelEventReceived] / [SmsAppResumed]: tự làm mới ngầm (1.3).
class SmsBloc extends Bloc<SmsEvent, SmsState> {
  SmsBloc({required SmsByDateRepository repository, DateTime Function()? clock})
    : _repository = repository,
      _now = clock ?? DateTime.now,
      super(SmsState(selectedDate: (clock ?? DateTime.now)())) {
    on<SmsDateSelected>(_onDateSelected);
    on<SmsLoadDataEvent>(_onLoadData, transformer: restartable());
    on<SmsChannelEventReceived>(_onChannelEvent);
    on<SmsAppResumed>(_onAppResumed);

    _changesSubscription = _repository.messageChanges.listen(
      (event) => add(SmsChannelEventReceived(event)),
    );
  }

  final SmsByDateRepository _repository;
  final DateTime Function() _now;
  StreamSubscription<ChannelEvent>? _changesSubscription;
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

  /// Tin mới chỉ xuất hiện ở "hôm nay" → chỉ làm mới khi đang xem hôm nay.
  /// Được duyệt / bị thu hồi đổi tập kênh → ngày nào cũng làm mới.
  void _onChannelEvent(
    SmsChannelEventReceived event,
    Emitter<SmsState> emit,
  ) {
    if (event.event.kind == ChannelEventKind.newMessage && !_isSameDay(state.selectedDate, _now())) {
      return;
    }
    add(const SmsLoadDataEvent(silent: true));
  }

  void _onAppResumed(SmsAppResumed event, Emitter<SmsState> emit) {
    if (!state.hasFetchedOnce) return;
    add(const SmsLoadDataEvent(silent: true));
  }

  Future<void> _onLoadData(
    SmsLoadDataEvent event,
    Emitter<SmsState> emit,
  ) async {
    if (!event.silent) emit(state.copyWith(isLoading: true));

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
          cachedAt: () => result.cachedAt,
        ),
      );
    } catch (error) {
      // Bỏ qua nếu request bị hủy bởi cancelToken
      if (cancelToken.isCancelled || error is RequestCancelledException) {
        return;
      }

      if (!event.silent) {
        ToastUtils.showError(
          AppL10n.current.smsLoadError,
          title: AppL10n.current.smsLoadErrorTitle,
        );
      }
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
    _changesSubscription?.cancel();
    _cancelToken?.cancel('SmsBloc closed');
    return super.close();
  }
}
