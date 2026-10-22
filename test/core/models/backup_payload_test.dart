import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/backup_payload.dart';

void main() {
  final payload = BackupPayload(
    deviceId: 'dev-1',
    deviceName: 'Pixel',
    deviceToken: 'tok',
    serverUrl: 'https://example.test',
    identityPrivateKey: 'priv',
    identityPublicKey: 'pub',
    channelKeys: const {
      'ch-a': {1: 'k1', 2: 'k2'},
      'ch-b': {5: 'k5'},
    },
    createdAt: DateTime.utc(2026, 10, 22, 4, 15),
  );

  test('JSON round-trip keeps every channel key and epoch', () {
    final back = BackupPayload.fromJson(
      jsonDecode(jsonEncode(payload.toJson())) as Map<String, dynamic>,
    );
    expect(back.deviceId, 'dev-1');
    expect(back.deviceName, 'Pixel');
    expect(back.deviceToken, 'tok');
    expect(back.serverUrl, 'https://example.test');
    expect(back.identityPrivateKey, 'priv');
    expect(back.identityPublicKey, 'pub');
    expect(back.channelKeys, payload.channelKeys);
    expect(back.createdAt.toUtc(), payload.createdAt);
    expect(back.isComplete, isTrue);
    expect(back.channelCount, 2);
  });

  test('missing identity → not complete; junk epochs are dropped', () {
    final back = BackupPayload.fromJson(const {
      'device': {'id': 'dev-1', 'token': 'tok'},
      'channels': {
        'ch-a': {'x': 'k', '3': ''},
        'ch-b': {'4': 'k4'},
      },
    });
    expect(back.isComplete, isFalse);
    expect(back.channelKeys, {
      'ch-b': {4: 'k4'},
    });
  });
}
