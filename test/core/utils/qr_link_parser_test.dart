import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/qr_link_parser.dart';

void main() {
  const code = 'AbCdEfGhIjKlMnOpQrSt_-';
  const host = 'sms-relay.hirusakunasaga.workers.dev';

  group('QrLinkParser.parse', () {
    test('https link on an allowed host → opaque code', () {
      expect(
        QrLinkParser.parse('https://$host/qr/$code', allowedHosts: {host}),
        const OpaqueQrLink(code),
      );
    });

    test('https link on a foreign host is rejected when hosts are known', () {
      expect(QrLinkParser.parse('https://evil.example/qr/$code', allowedHosts: {host}), isNull);
    });

    test('https link passes structural check when no host list is given (scanner)', () {
      expect(QrLinkParser.parse('https://any.example/qr/$code'), const OpaqueQrLink(code));
    });

    test('custom scheme smsnavigator://qr?code=', () {
      expect(QrLinkParser.parse('smsnavigator://qr?code=$code'), const OpaqueQrLink(code));
    });

    test('bare 22-char code (pasted / typed)', () {
      expect(QrLinkParser.parse('  $code  '), const OpaqueQrLink(code));
    });

    test('legacy v4 invite is still recognised during the transition', () {
      const v4 = 'smsnavigator://pair?v=4&s=session_123&t=token_abc&u=aHR0cHM6Ly9hcGkuaW8&e=1790999999999';
      expect(QrLinkParser.parse(v4), const LegacyInviteLink(v4));
    });

    test('rejects malformed codes and unrelated content', () {
      expect(QrLinkParser.parse(''), isNull);
      expect(QrLinkParser.parse('hello world'), isNull);
      expect(QrLinkParser.parse('smsnavigator://qr?code=short'), isNull);
      expect(QrLinkParser.parse('https://$host/qr/$code/extra', allowedHosts: {host}), isNull);
      expect(QrLinkParser.parse('https://$host/other/$code', allowedHosts: {host}), isNull);
      expect(QrLinkParser.parse('http://$host/qr/$code', allowedHosts: {host}), isNull);
    });
  });

  test('hostOf lower-cases and ignores junk', () {
    expect(QrLinkParser.hostOf('https://API.Example.com/path'), 'api.example.com');
    expect(QrLinkParser.hostOf(''), isNull);
    expect(QrLinkParser.hostOf(null), isNull);
  });
}
