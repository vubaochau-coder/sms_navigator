import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exceptions.dart';
import '../utils/app_logger.dart';
import '../l10n/app_l10n.dart';

/// Cung cấp device token để đính kèm vào header Authorization.
typedef DeviceTokenProvider = Future<String?> Function();

/// Cung cấp server URL động (đọc từ DeviceStorageService).
typedef ServerUrlProvider = Future<String?> Function();

/// Gọi khi một request bị 401 (BACKLOG 3.2); `true` = phiên đã được khôi phục,
/// gửi lại request một lần với token mới.
typedef UnauthorizedHandler = Future<bool> Function();

/// HTTP client đa năng sử dụng Dio cho toàn bộ API.
///
/// - Quản lý baseUrl động qua [ServerUrlProvider] (mặc định trỏ tới
///   `http://10.0.2.2:3000` của Android emulator hoặc `http://127.0.0.1:3000`).
/// - Tự động đính kèm header `Authorization: Bearer <device_token>`.
/// - Cung cấp các phương thức get/post/put/patch/delete động.
/// - Connect timeout 45 giây (đủ thời gian cho Render cold-start), receive/send timeout 30 giây.
/// - Chuẩn hóa lỗi: [NetworkException], [UnauthorizedException], [ApiException].
class ApiClient {
  static const String _ansiYellow = '\x1B[33m';
  static const String _ansiReset = '\x1B[0m';

  ApiClient({
    String? fallbackBaseUrl,
    Dio? dio,
    ServerUrlProvider? serverUrlProvider,
    DeviceTokenProvider? tokenProvider,
    Duration connectTimeout = const Duration(seconds: 45),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    Duration? requestTimeout,
  }) : _fallbackBaseUrl = fallbackBaseUrl ?? defaultBaseUrl,
       _serverUrlProvider = serverUrlProvider,
       _tokenProvider = tokenProvider,
       connectTimeout = requestTimeout ?? connectTimeout,
       receiveTimeout = requestTimeout ?? receiveTimeout,
       sendTimeout = requestTimeout ?? sendTimeout {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: _fallbackBaseUrl,
            connectTimeout: this.connectTimeout,
            receiveTimeout: this.receiveTimeout,
            sendTimeout: this.sendTimeout,
            headers: <String, dynamic>{
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final resolvedUrl = await _resolveBaseUrl();
          options.baseUrl = resolvedUrl;

          final isRegister = options.path.contains('/devices/register');
          if (!isRegister) {
            final token = await _tokenProvider?.call();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          if (kDebugMode) {
            options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;
            final queryInfo = options.queryParameters.isNotEmpty ? ' | Query: ${options.queryParameters}' : '';
            final bodyInfo = options.data != null ? ' | Payload: ${_sanitizeLogPayload(options.data)}' : '';
            debugPrint('$_ansiYellow🌐 [API REQ] [${options.method}] ${options.uri}$queryInfo$bodyInfo$_ansiReset');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final startTime = response.requestOptions.extra['request_start_time'] as int?;
            final durationStr = startTime != null ? ' (${DateTime.now().millisecondsSinceEpoch - startTime}ms)' : '';
            debugPrint('$_ansiYellow✅ [API RES] [${response.requestOptions.method}] ${response.requestOptions.uri}$durationStr [HTTP ${response.statusCode}] -> Data: ${response.data}$_ansiReset');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (kDebugMode) {
            final startTime = error.requestOptions.extra['request_start_time'] as int?;
            final durationStr = startTime != null ? ' (${DateTime.now().millisecondsSinceEpoch - startTime}ms)' : '';
            final statusCode = error.response?.statusCode != null ? ' [HTTP ${error.response?.statusCode}]' : '';
            final responseData = error.response?.data != null ? ' -> Data: ${error.response?.data}' : '';
            debugPrint('$_ansiYellow❌ [API ERR] [${error.requestOptions.method}] ${error.requestOptions.uri}$durationStr$statusCode: ${error.message}$responseData$_ansiReset');
          }
          final retried = await _retryAfterUnauthorized(error);
          if (retried != null) return handler.resolve(retried);
          return handler.next(error);
        },
      ),
    );
  }

  /// Base URL mặc định trỏ tới Cloudflare Worker proxy (chuyển tiếp tới Render).
  static const String defaultBaseUrl = 'https://sms-relay.hirusakunasaga.workers.dev';

  /// Base URL dùng khi chạy test/debug trực tiếp trên máy.
  static const String localBaseUrl = 'http://127.0.0.1:3000';

  late final Dio _dio;

  /// Xử lý 401 tập trung — gắn sau khi tạo (phụ thuộc vòng: recovery cần
  /// DeviceApiService, mà DeviceApiService cần ApiClient).
  UnauthorizedHandler? onUnauthorized;

  static const String _retriedAfter401 = 'retried_after_401';

  /// 401 trên request đã xác thực (không phải đăng ký, chưa retry) → khôi phục
  /// phiên rồi gửi lại đúng một lần; null = giữ nguyên lỗi.
  Future<Response<dynamic>?> _retryAfterUnauthorized(DioException error) async {
    final handler = onUnauthorized;
    final options = error.requestOptions;
    if (handler == null ||
        error.response?.statusCode != 401 ||
        options.path.contains('/devices/register') ||
        options.extra[_retriedAfter401] == true) {
      return null;
    }
    final recovered = await handler().catchError((Object _) => false);
    if (!recovered) return null;
    options.extra[_retriedAfter401] = true;
    try {
      // onRequest gắn lại Authorization bằng token mới
      return await _dio.fetch<dynamic>(options);
    } on DioException {
      return null;
    }
  }

  final String _fallbackBaseUrl;
  final ServerUrlProvider? _serverUrlProvider;
  final DeviceTokenProvider? _tokenProvider;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  Duration get requestTimeout => receiveTimeout;

  Dio get dio => _dio;

  Future<String> _resolveBaseUrl() async {
    final stored = await _serverUrlProvider?.call();
    if (stored != null && stored.trim().isNotEmpty) {
      final trimmed = stored.trim();
      // Tự động bỏ qua URL Render cũ nếu từng lưu vào storage trước đây
      if (trimmed.contains('sms-navigator-server.onrender.com')) {
        return _fallbackBaseUrl;
      }
      return trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
    }
    return _fallbackBaseUrl;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: body,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: body,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(String path, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return RequestCancelledException(
        e.message ?? AppL10n.current.networkRequestCancelled,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      AppLogger.w(
        'ApiClient',
        'Connection timed out (${connectTimeout.inSeconds}s) on ${e.requestOptions.uri}',
      );
      return NetworkException(
        AppL10n.current.networkConnectTimeout(connectTimeout.inSeconds),
      );
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      AppLogger.w(
        'ApiClient',
        'Request transfer timed out (${receiveTimeout.inSeconds}s) on ${e.requestOptions.uri}',
      );
      return NetworkException(
        AppL10n.current.networkTransferTimeout(receiveTimeout.inSeconds),
      );
    }
    final response = e.response;
    if (response != null) {
      if (response.statusCode == 401) {
        return UnauthorizedException(
          AppL10n.current.networkUnauthorized,
        );
      }
      if ((response.statusCode ?? 0) >= 500) {
        AppLogger.e(
          'ApiClient',
          'Server responded with HTTP ${response.statusCode} on ${e.requestOptions.uri}',
          e,
        );
      }
      String? errorCode;
      final dynamic data = response.data;
      if (data is Map) {
        final dynamic err = data['error'];
        if (err is String && err.isNotEmpty) errorCode = err;
      }
      return ApiException(
        AppL10n.current.networkServerError('${response.statusCode}'),
        statusCode: response.statusCode,
        errorCode: errorCode,
      );
    }
    AppLogger.w('ApiClient', 'Network error on ${e.requestOptions.uri}: ${e.message}');
    return NetworkException(AppL10n.current.networkUnreachable('${e.message}'));
  }

  static dynamic _sanitizeLogPayload(dynamic data) {
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (key.toLowerCase().contains('token') ||
            key.toLowerCase().contains('secret') ||
            key.toLowerCase().contains('password') ||
            key.toLowerCase().contains('private_key')) {
          sanitized[key] = (value is String && value.length > 8)
              ? '${value.substring(0, 4)}...***'
              : '***';
        } else {
          sanitized[key] = _sanitizeLogPayload(value);
        }
      }
      return sanitized;
    }
    return data;
  }

  void close() {
    _dio.close();
  }
}
