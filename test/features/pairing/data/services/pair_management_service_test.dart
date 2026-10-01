import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/paired_device_item.dart';

void main() {
  group('PairedDeviceItem Model Tests', () {
    test('fromReceiverJson correctly parses receiver item', () {
      final json = {
        'pair_id': 'pair_rec_01',
        'receiver_device_id': 'dev_rec_123',
        'device_name': 'Pixel 8 Malaysia',
        'platform': 'android',
        'is_active': true,
        'paired_at': '2026-09-30T10:00:00.000Z',
        'last_active_at': '2026-09-30T10:05:00.000Z',
      };

      final item = PairedDeviceItem.fromReceiverJson(json);
      expect(item.pairId, 'pair_rec_01');
      expect(item.deviceId, 'dev_rec_123');
      expect(item.displayName, 'Pixel 8 Malaysia');
      expect(item.isSender, isFalse);
      expect(item.formattedPairedAt, isNot('--'));
      expect(item.formattedLastActiveAt, isNot('Chưa có hoạt động'));
    });

    test('fromSenderJson correctly parses sender item', () {
      final json = {
        'pair_id': 'pair_send_01',
        'sender_device_id': 'dev_send_456',
        'device_name': 'Galaxy S24 Vietnam',
        'platform': 'android',
        'is_active': false,
        'paired_at': '2026-09-30T10:00:00.000Z',
      };

      final item = PairedDeviceItem.fromSenderJson(json);
      expect(item.pairId, 'pair_send_01');
      expect(item.deviceId, 'dev_send_456');
      expect(item.displayName, 'Galaxy S24 Vietnam');
      expect(item.isSender, isTrue);
      expect(item.formattedLastActiveAt, 'Chưa có hoạt động');
    });

    test('copyWith preserves properties and updates deviceName', () {
      const item = PairedDeviceItem(
        pairId: 'pair_1',
        deviceId: 'dev_1',
        deviceName: 'Device 1',
      );

      final updated = item.copyWith(deviceName: 'Device 2');
      expect(updated.deviceName, 'Device 2');
      expect(updated.pairId, 'pair_1');
      expect(updated.deviceId, 'dev_1');
    });
  });
}
