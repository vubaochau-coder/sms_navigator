import 'package:dio/dio.dart';

import '../enums/splash_status.dart';

/// Luồng khởi động của app (BACKLOG 3.3 / TD-3) — trước đây nằm thẳng trong
/// `SplashBloc` với 7 service. Phát lần lượt các bước dưới dạng [SplashStatus]
/// và kết thúc ở [SplashStatus.ready] hoặc [SplashStatus.awaitingSetupChoice];
/// lỗi chặn khởi động được ném ra (bloc quyết định thông điệp).
abstract class StartupRepository {
  /// [offerSetupChoice]: bản cài chưa đăng ký → dừng ở
  /// [SplashStatus.awaitingSetupChoice] (để khôi phục từ bản sao lưu) thay vì
  /// tự tạo danh tính mới.
  Stream<SplashStatus> bootstrap({
    required String defaultDeviceName,
    required bool offerSetupChoice,
    CancelToken? cancelToken,
  });

  /// Báo lỗi khởi động lên Crashlytics.
  Future<void> recordFailure(Object error, StackTrace stack);
}
