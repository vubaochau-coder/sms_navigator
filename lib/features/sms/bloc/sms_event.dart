import 'package:equatable/equatable.dart';

abstract class SmsEvent extends Equatable {
  const SmsEvent();

  @override
  List<Object?> get props => [];
}

/// User chọn ngày trên calendar (6.1).
/// Nghiệp vụ: BLoC sẽ kiểm tra date có khác không, emit selectedDate mới và tự add [SmsLoadDataEvent].
class SmsDateSelected extends SmsEvent {
  final DateTime date;

  const SmsDateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event thuần túy chịu trách nhiệm load dữ liệu SMS theo trạng thái state hiện tại.
/// Áp dụng bloc concurrency (restartable) và hỗ trợ CancelToken để hủy request cũ.
class SmsLoadDataEvent extends SmsEvent {
  const SmsLoadDataEvent();
}
