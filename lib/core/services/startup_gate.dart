import 'package:equatable/equatable.dart';

/// Kết quả kiểm tra cổng khởi động (BACKLOG 3.5).
class StartupGateResult extends Equatable {
  const StartupGateResult.open()
      : blocked = false,
        message = '';

  const StartupGateResult.maintenance(this.message) : blocked = true;

  /// `true` → dừng khởi động, hiện [message] kèm nút Thử lại.
  final bool blocked;

  /// Thông điệp từ cấu hình từ xa; rỗng → dùng câu mặc định.
  final String message;

  @override
  List<Object?> get props => [blocked, message];
}

/// Cổng chặn khởi động có điều khiển từ xa (vd bảo trì server).
///
/// Luôn **fail-open**: lỗi mạng / chưa cấu hình / quá thời gian → mở cổng,
/// để một sự cố của Remote Config không bao giờ khoá người dùng ngoài app.
abstract class StartupGate {
  Future<StartupGateResult> check();
}

/// Ném ra khi [StartupGate] chặn khởi động; SplashBloc hiển thị thông điệp
/// thay vì coi đây là lỗi (không ghi Crashlytics).
class StartupBlockedException implements Exception {
  const StartupBlockedException(this.message);

  final String message;

  @override
  String toString() => 'StartupBlockedException: $message';
}
