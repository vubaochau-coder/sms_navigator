import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/network/api_client.dart';
import 'package:sms_navigator/core/network/server_waker.dart';

ResponseBody _json(Object body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

ResponseBody _challenge() => ResponseBody.fromString(
  '<!DOCTYPE html><html><head><title>Just a moment...</title></head></html>',
  429,
  headers: {
    Headers.contentTypeHeader: ['text/html; charset=UTF-8'],
    'cf-mitigated': ['challenge'],
  },
);

/// API behind the Worker: challenged until [awake], then answers 200.
class _WorkerAdapter implements HttpClientAdapter {
  bool awake = false;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return awake ? _json({'success': true}, 200) : _challenge();
  }

  @override
  void close({bool force = false}) {}
}

/// Direct Render /health: wakes the worker adapter when [succeeds].
class _WakeAdapter implements HttpClientAdapter {
  _WakeAdapter(this.worker);

  final _WorkerAdapter worker;
  bool succeeds = true;

  /// Số ping đầu tiên vẫn bị hibernation gate trả 429 (đang khởi động).
  int asleepForPings = 0;
  int pings = 0;
  final List<RequestOptions> requests = [];
  Completer<void>? gate;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    pings++;
    requests.add(options);
    await gate?.future;
    if (!succeeds || pings <= asleepForPings) {
      return ResponseBody.fromString('Too Many Requests', 429, headers: {
        'x-render-routing': ['hibernate-rate-limited'],
      });
    }
    worker.awake = true;
    return _json({'status': 'healthy'}, 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _WorkerAdapter worker;
  late _WakeAdapter wakeAdapter;
  late DateTime now;
  late ServerWaker waker;

  ApiClient clientFor(String baseUrl, {ServerWaker? serverWaker}) => ApiClient(
    dio: Dio()..httpClientAdapter = worker,
    serverUrlProvider: () async => baseUrl,
    tokenProvider: () async => 'secret-token',
    serverWaker: serverWaker,
  );

  setUp(() {
    worker = _WorkerAdapter();
    wakeAdapter = _WakeAdapter(worker);
    now = DateTime(2026, 11, 24, 8);
    waker = ServerWaker(
      dio: Dio()..httpClientAdapter = wakeAdapter,
      clock: () => now,
      sleep: (d) async => now = now.add(d),
    );
  });

  group('isEdgeBlockedResponse', () {
    Response<dynamic> resp(int status, Object? data) =>
        Response<dynamic>(requestOptions: RequestOptions(), statusCode: status, data: data);

    test('challenge HTML / plain text 429 is edge-blocked', () {
      expect(isEdgeBlockedResponse(resp(429, '<html>Just a moment...</html>')), isTrue);
      expect(isEdgeBlockedResponse(resp(429, 'Too Many Requests')), isTrue);
      expect(isEdgeBlockedResponse(resp(503, null)), isTrue);
    });

    test('server JSON envelope is never edge-blocked', () {
      expect(isEdgeBlockedResponse(resp(429, {'success': false, 'error': 'RATE_LIMITED'})), isFalse);
      expect(isEdgeBlockedResponse(resp(403, {'success': false, 'error': 'FORBIDDEN'})), isFalse);
      expect(isEdgeBlockedResponse(resp(500, '<html>oops</html>')), isFalse);
    });
  });

  test('edge block → wake ping via direct /health → retried once through the Worker', () async {
    final client = clientFor(ApiClient.defaultBaseUrl, serverWaker: waker);

    final data = await client.post('/api/v2/devices/register', body: {'device_id': 'x'});

    expect(data, {'success': true});
    expect(wakeAdapter.pings, 1);
    expect(worker.requests, hasLength(2));
    expect(worker.requests.every((r) => r.baseUrl == ApiClient.defaultBaseUrl), isTrue);
    // The direct URL only ever sees an anonymous GET /health.
    final ping = wakeAdapter.requests.single;
    expect(ping.method, 'GET');
    expect(ping.uri.toString(), ServerWaker.defaultWakeUrl);
    expect(ping.headers.containsKey('Authorization'), isFalse);
    expect(ping.data, isNull);
  });

  test('keeps polling through hibernation 429s until /health is healthy', () async {
    wakeAdapter.asleepForPings = 3;
    final client = clientFor(ApiClient.defaultBaseUrl, serverWaker: waker);
    final started = now;
    final wakingStates = <bool>[];
    waker.waking.addListener(() => wakingStates.add(waker.waking.value));

    expect(await client.get('/api/v2/devices/me'), {'success': true});
    expect(wakeAdapter.pings, 4);
    expect(now.difference(started), const Duration(seconds: 3 + 5 + 8));
    expect(wakingStates, [true, false]);
    expect(worker.requests, hasLength(2));
  });

  test('never wakes within the deadline → ServerStartingException, API request not retried', () async {
    wakeAdapter.succeeds = false;
    final client = clientFor(ApiClient.defaultBaseUrl, serverWaker: waker);
    final started = now;

    await expectLater(client.get('/api/v2/devices/me'), throwsA(isA<ServerStartingException>()));
    expect(wakeAdapter.pings, greaterThan(5));
    expect(now.difference(started), lessThan(waker.wakeDeadline));
    expect(worker.requests, hasLength(1));
  });

  test('cooldown: a failed wake is not repeated within 30 s; resetCooldown forces a new attempt', () async {
    wakeAdapter.succeeds = false;
    final client = clientFor(ApiClient.defaultBaseUrl, serverWaker: waker);

    await expectLater(client.get('/api/v2/devices/me'), throwsA(isA<ServerStartingException>()));
    final pingsAfterFirst = wakeAdapter.pings;
    now = now.add(const Duration(seconds: 10));
    await expectLater(client.get('/api/v2/devices/me'), throwsA(isA<ServerStartingException>()));
    expect(wakeAdapter.pings, pingsAfterFirst);

    // e.g. the user just woke the server in the browser
    waker.resetCooldown();
    wakeAdapter.succeeds = true;
    expect(await client.get('/api/v2/devices/me'), {'success': true});
    expect(wakeAdapter.pings, pingsAfterFirst + 1);
  });

  test('single-flight: concurrent blocked requests share one wake ping', () async {
    wakeAdapter.gate = Completer<void>();
    final client = clientFor(ApiClient.defaultBaseUrl, serverWaker: waker);

    final a = client.get('/api/v2/channels');
    final b = client.get('/api/v2/messages');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    wakeAdapter.gate!.complete();

    expect(await a, {'success': true});
    expect(await b, {'success': true});
    expect(wakeAdapter.pings, 1);
  });

  test('custom server URL never triggers a wake ping', () async {
    final client = clientFor('https://my-own-server.example.com', serverWaker: waker);

    await expectLater(client.get('/api/v2/devices/me'), throwsA(isA<ServerStartingException>()));
    expect(wakeAdapter.pings, 0);
  });

  test('no waker configured (FCM background) → fails fast without pinging', () async {
    final client = clientFor(ApiClient.defaultBaseUrl);

    await expectLater(client.get('/api/v2/devices/me'), throwsA(isA<ServerStartingException>()));
    expect(wakeAdapter.pings, 0);
  });

  test('server JSON 429 RATE_LIMITED is a plain ApiException and never wakes', () async {
    final dio = Dio()
      ..httpClientAdapter = _FixedAdapter(_json({'success': false, 'error': 'RATE_LIMITED'}, 429));
    final client = ApiClient(dio: dio, serverUrlProvider: () async => ApiClient.defaultBaseUrl, serverWaker: waker);

    final error = await client.get('/api/v2/devices/me').then<Object?>((_) => null, onError: (Object e) => e);
    expect(error, isA<ApiException>());
    expect(error, isNot(isA<ServerStartingException>()));
    expect((error as ApiException).statusCode, 429);
    expect(error.errorCode, 'RATE_LIMITED');
    expect(wakeAdapter.pings, 0);
  });
}

class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.body);
  final ResponseBody body;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      body;

  @override
  void close({bool force = false}) {}
}
