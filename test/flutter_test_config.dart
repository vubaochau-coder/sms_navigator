import 'dart:async';
import 'dart:io';

/// Chạy trước mọi file test (cơ chế `flutter_test_config.dart` của flutter_test).
///
/// Test phải hermetic: chặn mọi kết nối socket ra ngoài loopback để không test
/// nào vô tình gọi server production (`ApiClient.defaultBaseUrl`). Test cần
/// HTTP thì inject fake repository / `Dio` adapter, hoặc dựng server trên
/// `127.0.0.1`.
///
/// `testWidgets` còn được `TestWidgetsFlutterBinding` thay `HttpOverrides`
/// bằng client giả trả 400; lớp này phủ các file chỉ dùng `test()`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  HttpOverrides.global = _LoopbackOnlyHttpOverrides();
  await testMain();
}

class _LoopbackOnlyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) {
        // Xét host đích, không phải proxy: proxy chạy trên loopback (HTTPS_PROXY)
        // vẫn sẽ chuyển tiếp ra Internet.
        if (!_isLoopback(uri.host)) {
          throw SocketException(
            'Blocked outbound connection to ${uri.host} in tests '
            '(see test/flutter_test_config.dart)',
          );
        }
        return Socket.startConnect(
          proxyHost ?? uri.host,
          proxyPort ?? uri.port,
        );
      };
  }

  static bool _isLoopback(String host) {
    if (host == 'localhost') return true;
    final address = InternetAddress.tryParse(host);
    return address != null && address.isLoopback;
  }
}
