import 'dart:async';
import 'dart:io';

/// Cấu hình chung cho mọi test (BACKLOG 3.1 — test hermetic).
///
/// Chặn mọi kết nối mạng ra ngoài loopback: widget test dựng `AppBootstrap`
/// thật nên `ApiClient` mặc định trỏ tới server production. Một request lọt
/// ra ngoài sẽ thất bại ngay bằng `SocketException` (app coi là lỗi mạng)
/// thay vì chạm vào server thật hoặc phụ thuộc mạng của máy chạy test/CI.
///
/// Test cần HTTP cục bộ (`HttpServer` trên 127.0.0.1) vẫn chạy bình thường.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final overrides = _OfflineHttpOverrides();
  HttpOverrides.global = overrides;
  await HttpOverrides.runWithHttpOverrides(() async => testMain(), overrides);
}

class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      // Xét host đích, không phải proxy: proxy chạy trên loopback (HTTPS_PROXY)
      // vẫn chuyển tiếp ra Internet.
      if (_isLoopback(uri.host)) {
        return Socket.startConnect(
          proxyHost ?? uri.host,
          proxyPort ?? uri.port,
        );
      }
      return Future<ConnectionTask<Socket>>.error(
        SocketException(
          'Network access is disabled in tests (attempted ${uri.host}:${uri.port})',
        ),
      );
    };
    return client;
  }

  static bool _isLoopback(String host) {
    if (host == 'localhost') return true;
    final address = InternetAddress.tryParse(host);
    return address != null && address.isLoopback;
  }
}
