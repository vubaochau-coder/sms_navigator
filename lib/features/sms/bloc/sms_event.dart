import 'package:equatable/equatable.dart';

abstract class SmsEvent extends Equatable {
  const SmsEvent();

  @override
  List<Object?> get props => [];
}

/// User chọn ngày trên calendar (6.1) hoặc cần load lại hôm nay lúc mở app.
class SmsDateSelected extends SmsEvent {
  final DateTime date;

  const SmsDateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

/// Pull-to-refresh / retry sau lỗi.
class SmsRefreshed extends SmsEvent {
  const SmsRefreshed();
}

// Backward compatibility typedefs
typedef SmsByDateEvent = SmsEvent;
typedef SmsByDateSelected = SmsDateSelected;
typedef SmsByDateRefreshed = SmsRefreshed;
typedef OtpByDateEvent = SmsEvent;
typedef OtpByDateSelected = SmsDateSelected;
typedef OtpByDateRefreshed = SmsRefreshed;
