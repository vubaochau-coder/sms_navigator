import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';

void main() {
  test('parses code + qr_url and prefers qr_url for sharing', () {
    final session = PairingSessionModel.fromMap({
      'session_id': 's-1',
      'pairing_token': 't',
      'expires_at': '2026-10-21T10:10:00.000Z',
      'invite_url': 'smsnavigator://pair?v=4&s=s-1',
      'code': 'AbCdEfGhIjKlMnOpQrSt_-',
      'qr_url': 'https://host/qr/AbCdEfGhIjKlMnOpQrSt_-',
    });
    expect(session.code, 'AbCdEfGhIjKlMnOpQrSt_-');
    expect(session.shareUrl, 'https://host/qr/AbCdEfGhIjKlMnOpQrSt_-');
  });

  test('falls back to the v4 invite_url when the server has no qr_url yet', () {
    final session = PairingSessionModel.fromMap({
      'session_id': 's-1',
      'pairing_token': 't',
      'expires_at': '2026-10-21T10:10:00.000Z',
      'invite_url': 'smsnavigator://pair?v=4&s=s-1',
    });
    expect(session.shareUrl, 'smsnavigator://pair?v=4&s=s-1');
  });
}
