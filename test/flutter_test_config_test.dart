import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the hermetic-test setup in `flutter_test_config.dart`.
void main() {
  test('outbound HTTP is blocked, even through a configured proxy', () async {
    await expectLater(
      Future(() => HttpClient().getUrl(Uri.parse('https://example.com/'))),
      throwsA(isA<SocketException>()),
    );
  });

  test('loopback HTTP still works', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen(
      (request) => request.response
        ..write('ok')
        ..close(),
    );

    final request = await HttpClient().getUrl(
      Uri.parse('http://127.0.0.1:${server.port}/'),
    );
    final response = await request.close();
    expect(response.statusCode, 200);
  });
}
