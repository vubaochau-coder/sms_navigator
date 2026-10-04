import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/network/api_client.dart';

class _MockAdapter implements HttpClientAdapter {
  int requestCount = 0;
  List<String> authHeadersSeen = [];
  int fail401Times = 1;
  bool failRegister401 = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    final auth = options.headers['Authorization'] as String?;
    if (auth != null) {
      authHeadersSeen.add(auth);
    }

    if (failRegister401 && options.path.contains('/devices/register')) {
      return ResponseBody.fromString(
        '{"success": false, "error": "UNAUTHORIZED"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path.contains('/api/test-401')) {
      if (fail401Times > 0) {
        fail401Times--;
        return ResponseBody.fromString(
          '{"success": false, "error": "UNAUTHORIZED"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        '{"success": true, "data": "ok"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      '{"success": true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiClient 401 Re-Auth & Retry', () {
    test('retries failed 401 request with new token when onUnauthorized succeeds', () async {
      final mockAdapter = _MockAdapter()..fail401Times = 1;
      final dio = Dio()..httpClientAdapter = mockAdapter;

      String currentToken = 'token_old';
      var reAuthCount = 0;

      final client = ApiClient(
        dio: dio,
        tokenProvider: () async => currentToken,
        onUnauthorized: () async {
          reAuthCount++;
          currentToken = 'token_new';
          return true;
        },
      );

      final res = await client.get('/api/test-401');
      expect(res, {'success': true, 'data': 'ok'});
      expect(reAuthCount, 1);
      expect(mockAdapter.requestCount, 2);
      expect(mockAdapter.authHeadersSeen, ['Bearer token_old', 'Bearer token_new']);
    });

    test('single-flight mutex prevents multiple parallel re-auth calls', () async {
      final mockAdapter = _MockAdapter()..fail401Times = 2;
      final dio = Dio()..httpClientAdapter = mockAdapter;

      String currentToken = 'token_old';
      var reAuthCount = 0;

      final client = ApiClient(
        dio: dio,
        tokenProvider: () async => currentToken,
        onUnauthorized: () async {
          reAuthCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          currentToken = 'token_new';
          return true;
        },
      );

      final results = await Future.wait([
        client.get('/api/test-401'),
        client.get('/api/test-401'),
      ]);

      expect(results[0], {'success': true, 'data': 'ok'});
      expect(results[1], {'success': true, 'data': 'ok'});
      expect(reAuthCount, 1); // Mutex ensures only 1 re-auth
    });

    test('throws UnauthorizedException when onUnauthorized is null', () async {
      final mockAdapter = _MockAdapter()..fail401Times = 99;
      final dio = Dio()..httpClientAdapter = mockAdapter;

      final client = ApiClient(
        dio: dio,
        tokenProvider: () async => 'token_old',
      );

      expect(
        () => client.get('/api/test-401'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('does not retry when register endpoint itself returns 401', () async {
      final mockAdapter = _MockAdapter()..failRegister401 = true;
      final dio = Dio()..httpClientAdapter = mockAdapter;

      var reAuthCalled = false;
      final client = ApiClient(
        dio: dio,
        onUnauthorized: () async {
          reAuthCalled = true;
          return true;
        },
      );

      expect(
        () => client.post('/api/v2/devices/register', body: {}),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(reAuthCalled, isFalse);
    });
  });
}
