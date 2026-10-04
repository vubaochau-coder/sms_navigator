import 'package:equatable/equatable.dart';

import '../../../core/models/channel_message_model.dart';

/// Trạng thái màn SMS theo ngày (MOBILE_FEATURES 6.1–6.4):
/// - ngày không có tin → empty
/// - mất mạng / lỗi → bắn ToastUtils từ BLoC
/// - tin chưa decrypt được (thiếu key) → hiển thị placeholder cảnh báo
class SmsState extends Equatable {
  final DateTime selectedDate;
  final bool isLoading;
  final List<ChannelMessageModel> messages;
  final bool truncated;
  final bool hasFetchedOnce;

  const SmsState({
    required this.selectedDate,
    this.isLoading = false,
    this.messages = const [],
    this.truncated = false,
    this.hasFetchedOnce = false,
  });

  bool get isEmpty => !isLoading && messages.isEmpty;

  SmsState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    List<ChannelMessageModel>? messages,
    bool? truncated,
    bool? hasFetchedOnce,
  }) {
    return SmsState(
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      truncated: truncated ?? this.truncated,
      hasFetchedOnce: hasFetchedOnce ?? this.hasFetchedOnce,
    );
  }

  @override
  List<Object?> get props => [
    selectedDate,
    isLoading,
    messages,
    truncated,
    hasFetchedOnce,
  ];
}

// Backward compatibility typedefs
typedef SmsByDateState = SmsState;
typedef OtpByDateState = SmsState;
