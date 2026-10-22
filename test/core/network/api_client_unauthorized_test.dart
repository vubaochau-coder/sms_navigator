import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/network/api_client.dart';

/// Answers 401 until the token is "fresh", then 200 — and records the auth headers.
class _AuthAdapter implements HttpClientAdapter {
  final List<String?> authHeaders = [];
  String acceptedToken = 'fresh';

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final auth = options.headers['Authorization'] as String?;
    authHeaders.add(auth);
    final ok = auth == 'Bearer $acceptedToken';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'success': true} : {'success': false, 'error': 'UNAUTHORIZED'}),
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _AuthAdapter adapter;
  late String token;
  late int recoveries;
  late ApiClient client;

  setUp(() {
    adapter = _AuthAdapter();
    token = 'stale';
    recoveries = 0;
    final dio = Dio()..httpClientAdapter = adapter;
    client = ApiClient(dio: dio, serverUrlProvider: () async => 'http://127.0.0.1:9', tokenProvider: () async => token);
  });

  test('a 401 triggers recovery once, then the request is retried with the new token', () async {
    client.onUnauthorized = () async {
      recoveries++;
      token = 'fresh';
      return true;
    };

    final data = await client.get('/api/v2/channels');

    expect(data, {'success': true});
    expect(recoveries, 1);
    expect(adapter.authHeaders, ['Bearer stale', 'Bearer fresh']);
  });

  test('failed recovery surfaces UnauthorizedException without retrying', () async {
    client.onUnauthorized = () async {
      recoveries++;
      return false;
    };

    await expectLater(client.get('/api/v2/channels'), throwsA(isA<UnauthorizedException>()));
    expect(recoveries, 1);
    expect(adapter.authHeaders, hasLength(1));
  });

  test('still 401 after recovery → no second recovery loop', () async {
    adapter.acceptedToken = 'never';
    client.onUnauthorized = () async {
      recoveries++;
      token = 'fresh';
      return true;
    };

    await expectLater(client.get('/api/v2/channels'), throwsA(isA<UnauthorizedException>()));
    expect(recoveries, 1);
    expect(adapter.authHeaders, hasLength(2));
  });

  test('without a handler a 401 is just UnauthorizedException', () async {
    await expectLater(client.get('/api/v2/channels'), throwsA(isA<UnauthorizedException>()));
  });
}
