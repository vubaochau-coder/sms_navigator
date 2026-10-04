import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/app_exceptions.dart';
import '../utils/app_logger.dart';

/// Cung cấp device token để đính kèm vào header Authorization.
typedef DeviceTokenProvider = Future<String?> Function();

/// Cung cấp server URL động (đọc từ DeviceStorageService).
typedef ServerUrlProvider = Future<String?> Function();

/// HTTP client đa năng sử dụng Dio cho toàn bộ API.
///
/// - Quản lý baseUrl động qua [ServerUrlProvider] (mặc định trỏ tới
///   `http://10.0.2.2:3000` của Android emulator hoặc `http://127.0.0.1:3000`).
/// - Tự động đính kèm header `Authorization: Bearer <device_token>`.
/// - Cung cấp các phương thức get/post/put/patch/delete động.
/// - Timeout 10 giây cho mọi request.
/// - Chuẩn hóa lỗi: [NetworkException], [UnauthorizedException], [ApiException].
class ApiClient {
  ApiClient({
    String? fallbackBaseUrl,
    Dio? dio,
    ServerUrlProvider? serverUrlProvider,
    DeviceTokenProvider? tokenProvider,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _fallbackBaseUrl = fallbackBaseUrl ?? defaultBaseUrl,
       _serverUrlProvider = serverUrlProvider,
       _tokenProvider = tokenProvider {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: _fallbackBaseUrl,
            connectTimeout: requestTimeout,
            receiveTimeout: requestTimeout,
            sendTimeout: requestTimeout,
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
          final token = await _tokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Base URL mặc định trỏ tới Production server trên Render.
  static const String defaultBaseUrl = 'https://sms-navigator-server.onrender.com';

  /// Base URL dùng khi chạy test/debug trực tiếp trên máy.
  static const String localBaseUrl = 'http://127.0.0.1:3000';

  late final Dio _dio;

  final String _fallbackBaseUrl;
  final ServerUrlProvider? _serverUrlProvider;
  final DeviceTokenProvider? _tokenProvider;
  final Duration requestTimeout;

  Dio get dio => _dio;

  Future<String> _resolveBaseUrl() async {
    final stored = await _serverUrlProvider?.call();
    if (stored != null && stored.trim().isNotEmpty) {
      final trimmed = stored.trim();
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
        e.message ?? 'Yêu cầu mạng đã bị hủy bỏ.',
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      AppLogger.w('ApiClient', 'Connection timed out on ${e.requestOptions.uri}');
      return NetworkException(
        'Kết nối tới máy chủ quá thời gian chờ (${requestTimeout.inSeconds}s).',
      );
    }
    final response = e.response;
    if (response != null) {
      if (response.statusCode == 401) {
        return const UnauthorizedException(
          'Phiên xác thực thiết bị không hợp lệ hoặc đã hết hạn (401).',
        );
      }
      if ((response.statusCode ?? 0) >= 500) {
        AppLogger.e(
          'ApiClient',
          'Server responded with HTTP ${response.statusCode} on ${e.requestOptions.uri}',
          e,
        );
      }
      return ApiException(
        'Máy chủ trả về lỗi (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    AppLogger.w('ApiClient', 'Network error on ${e.requestOptions.uri}: ${e.message}');
    return NetworkException('Không thể kết nối tới máy chủ: ${e.message}');
  }

  void close() {
    _dio.close();
  }
}
