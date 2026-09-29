import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exceptions.dart';

/// Cung cấp device token để đính kèm vào header Authorization.
typedef DeviceTokenProvider = Future<String?> Function();

/// Cung cấp server URL động (đọc từ DeviceStorageService).
typedef ServerUrlProvider = Future<String?> Function();

/// HTTP client đa năng cho toàn bộ REST API của ứng dụng.
///
/// - Quản lý baseUrl (mặc định trỏ tới server chạy trên máy phát triển,
///   qua alias `10.0.2.2` của Android emulator hoặc `127.0.0.1`).
/// - Tự động đính kèm header `Authorization: Bearer <device_token>`.
/// - Timeout 10 giây cho mọi request.
/// - Chuẩn hóa lỗi: [NetworkException], [UnauthorizedException], [ApiException].
class ApiClient {
  ApiClient({
    String? fallbackBaseUrl,
    http.Client? client,
    ServerUrlProvider? serverUrlProvider,
    DeviceTokenProvider? tokenProvider,
    this.requestTimeout = const Duration(seconds: 10),
  })  : _fallbackBaseUrl = fallbackBaseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client(),
        _serverUrlProvider = serverUrlProvider,
        _tokenProvider = tokenProvider;

  /// Base URL mặc định cho Android emulator (10.0.2.2 trỏ về 127.0.0.1 máy chủ).
  static const String defaultBaseUrl = 'http://10.0.2.2:3000';

  /// Base URL dùng khi chạy test/debug trực tiếp trên máy.
  static const String localBaseUrl = 'http://127.0.0.1:3000';

  final http.Client _client;
  final String _fallbackBaseUrl;
  final ServerUrlProvider? _serverUrlProvider;
  final DeviceTokenProvider? _tokenProvider;
  final Duration requestTimeout;

  Future<Uri> _buildUri(
    String path,
    Map<String, String>? queryParameters,
  ) async {
    final resolved = await _resolveBaseUrl();
    final base =
        resolved.endsWith('/')
            ? resolved.substring(0, resolved.length - 1)
            : resolved;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base/$normalizedPath')
        .replace(queryParameters: queryParameters);
  }

  Future<String> _resolveBaseUrl() async {
    final stored = await _serverUrlProvider?.call();
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    return _fallbackBaseUrl;
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = await _buildUri(path, queryParameters);
    final headers = await _buildHeaders();
    final response = await _send(() => _client.get(uri, headers: headers));
    return _decodeBody(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = await _buildUri(path, null);
    final headers = await _buildHeaders();
    final response = await _send(
      () => _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
    return _decodeBody(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = await _buildUri(path, null);
    final headers = await _buildHeaders();
    final response = await _send(
      () => _client.put(
        uri,
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
    return _decodeBody(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = await _buildUri(path, null);
    final headers = await _buildHeaders();
    final response = await _send(() => _client.delete(uri, headers: headers));
    return _decodeBody(response);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request().timeout(requestTimeout);
    } on TimeoutException {
      throw NetworkException(
        'Kết nối tới máy chủ quá thời gian chờ '
        '(${requestTimeout.inSeconds}s).',
      );
    } on http.ClientException catch (e) {
      throw NetworkException('Không thể kết nối tới máy chủ: ${e.message}');
    } catch (e) {
      throw NetworkException('Lỗi kết nối mạng: $e');
    }
    return _handleResponse(response);
  }

  http.Response _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      return response;
    }
    if (statusCode == 401) {
      throw UnauthorizedException(
        'Phiên xác thực thiết bị không hợp lệ hoặc đã hết hạn (401).',
      );
    }
    throw ApiException(
      'Máy chủ trả về lỗi (HTTP $statusCode).',
      statusCode: statusCode,
    );
  }

  dynamic _decodeBody(http.Response response) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw ApiException(
        'Dữ liệu trả về từ máy chủ không hợp lệ.',
        statusCode: response.statusCode,
      );
    }
  }

  void close() {
    _client.close();
  }
}
