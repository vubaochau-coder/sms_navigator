import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/channel_message_model.dart';
import '../../data/repositories/otp_by_date_repository.dart';

/// Trạng thái rỗng/lỗi có thông điệp rõ ràng (MOBILE_FEATURES 6.4):
/// - ngày không có tin → empty
/// - mất mạng → error với retry
/// - tin chưa decrypt được (thiếu key) → dòng lỗi riêng, không chết im
class OtpByDateState extends Equatable {
  final DateTime selectedDate;
  final bool isLoading;
  final List<ChannelMessageModel> messages;
  final bool truncated;
  final String? errorMessage;
  final bool hasFetchedOnce;

  const OtpByDateState({
    required this.selectedDate,
    this.isLoading = false,
    this.messages = const [],
    this.truncated = false,
    this.errorMessage,
    this.hasFetchedOnce = false,
  });

  bool get isEmpty => !isLoading && errorMessage == null && messages.isEmpty;

  OtpByDateState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    List<ChannelMessageModel>? messages,
    bool? truncated,
    String? errorMessage,
    bool? hasFetchedOnce,
    bool clearError = false,
  }) {
    return OtpByDateState(
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      truncated: truncated ?? this.truncated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasFetchedOnce: hasFetchedOnce ?? this.hasFetchedOnce,
    );
  }

  @override
  List<Object?> get props => [
    selectedDate,
    isLoading,
    messages,
    truncated,
    errorMessage,
    hasFetchedOnce,
  ];
}

abstract class OtpByDateEvent extends Equatable {
  const OtpByDateEvent();

  @override
  List<Object?> get props => [];
}

/// User chọn ngày trên calendar (6.1) hoặc cần load lại hôm nay lúc mở app.
class OtpByDateSelected extends OtpByDateEvent {
  final DateTime date;

  const OtpByDateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

/// Pull-to-refresh / retry sau lỗi.
class OtpByDateRefreshed extends OtpByDateEvent {
  const OtpByDateRefreshed();
}

/// Bloc màn OTP hôm nay: mỗi lần mở là một lần fetch (không local store).
class OtpByDateBloc extends Bloc<OtpByDateEvent, OtpByDateState> {
  OtpByDateBloc({required OtpByDateRepository repository})
    : _repository = repository,
      super(OtpByDateState(selectedDate: DateTime.now())) {
    on<OtpByDateSelected>(_onDateSelected, transformer: droppable());
    on<OtpByDateRefreshed>(_onRefreshed, transformer: droppable());
  }

  final OtpByDateRepository _repository;

  Future<void> _onDateSelected(
    OtpByDateSelected event,
    Emitter<OtpByDateState> emit,
  ) async {
    await _load(event.date, emit);
  }

  Future<void> _onRefreshed(
    OtpByDateRefreshed event,
    Emitter<OtpByDateState> emit,
  ) async {
    await _load(state.selectedDate, emit);
  }

  Future<void> _load(DateTime date, Emitter<OtpByDateState> emit) async {
    emit(
      state.copyWith(
        selectedDate: date,
        isLoading: true,
        clearError: true,
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
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không tải được OTP của ngày này. Kiểm tra kết nối và thử lại.',
        ),
      );
    }
  }
}
