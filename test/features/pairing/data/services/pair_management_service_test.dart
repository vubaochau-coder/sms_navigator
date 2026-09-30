import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/paired_device_item.dart';
import 'package:sms_navigator/features/pairing/data/services/pair_management_service.dart';

class _FakePairManagementService implements PairManagementService {
  List<PairedDeviceItem> receivers = [];
  List<PairedDeviceItem> senders = [];
  bool toggleSuccess = true;
  bool revokeSuccess = true;

  String? lastToggledPairId;
  bool? lastToggledIsActive;
  String? lastRevokedPairId;

  @override
  Future<List<PairedDeviceItem>> getPairedReceivers({
    CancelToken? cancelToken,
  }) async => receivers;

  @override
  Future<List<PairedDeviceItem>> getPairedSenders({
    CancelToken? cancelToken,
  }) async => senders;

  @override
  Future<bool> togglePairActive({
    required String pairId,
    required bool isActive,
    CancelToken? cancelToken,
  }) async {
    lastToggledPairId = pairId;
    lastToggledIsActive = isActive;
    if (toggleSuccess) {
      final idx = receivers.indexWhere((e) => e.pairId == pairId);
      if (idx != -1) {
        receivers[idx] = receivers[idx].copyWith(isActive: isActive);
      }
    }
    return toggleSuccess;
  }

  @override
  Future<bool> revokePair(String pairId, {CancelToken? cancelToken}) async {
    lastRevokedPairId = pairId;
    if (revokeSuccess) {
      receivers.removeWhere((e) => e.pairId == pairId);
      senders.removeWhere((e) => e.pairId == pairId);
    }
    return revokeSuccess;
  }
}

void main() {
  group('PairedDeviceItem Model Tests', () {
    test('fromReceiverJson correctly parses receiver item', () {
      final json = {
        'pair_id': 'pair_rec_01',
        'receiver_device_id': 'dev_rec_123',
        'device_name': 'Pixel 8 Malaysia',
        'platform': 'android',
        'is_active': true,
        'paired_at': 1727620000,
        'last_relayed_at': 1727620500,
      };

      final item = PairedDeviceItem.fromReceiverJson(json);
      expect(item.pairId, 'pair_rec_01');
      expect(item.deviceId, 'dev_rec_123');
      expect(item.displayName, 'Pixel 8 Malaysia');
      expect(item.isActive, isTrue);
      expect(item.isSender, isFalse);
      expect(item.formattedPairedAt, isNot('--'));
      expect(item.formattedLastRelayedAt, isNot('Chưa có lượt gửi'));
    });

    test('fromSenderJson correctly parses sender item', () {
      final json = {
        'pair_id': 'pair_send_01',
        'sender_device_id': 'dev_send_456',
        'device_name': 'Galaxy S24 Vietnam',
        'platform': 'android',
        'is_active': false,
        'paired_at': 1727620000,
      };

      final item = PairedDeviceItem.fromSenderJson(json);
      expect(item.pairId, 'pair_send_01');
      expect(item.deviceId, 'dev_send_456');
      expect(item.displayName, 'Galaxy S24 Vietnam');
      expect(item.isActive, isFalse);
      expect(item.isSender, isTrue);
      expect(item.formattedLastRelayedAt, 'Chưa có lượt gửi');
    });

    test('copyWith preserves properties and updates isActive', () {
      const item = PairedDeviceItem(
        pairId: 'pair_1',
        deviceId: 'dev_1',
        isActive: true,
        deviceName: 'Device 1',
      );

      final updated = item.copyWith(isActive: false);
      expect(updated.isActive, isFalse);
      expect(updated.pairId, 'pair_1');
      expect(updated.deviceName, 'Device 1');
    });
  });

  group('PairManagementService Tests', () {
    test('togglePairActive toggles state and updates records', () async {
      final service = _FakePairManagementService();
      service.receivers = [
        const PairedDeviceItem(
          pairId: 'pair_toggle_test',
          deviceId: 'rec_01',
          isActive: true,
          deviceName: 'Phone 1',
        ),
      ];

      final success = await service.togglePairActive(
        pairId: 'pair_toggle_test',
        isActive: false,
      );

      expect(success, isTrue);
      expect(service.lastToggledPairId, 'pair_toggle_test');
      expect(service.lastToggledIsActive, isFalse);
      expect(service.receivers.first.isActive, isFalse);
    });

    test('revokePair removes paired record', () async {
      final service = _FakePairManagementService();
      service.receivers = [
        const PairedDeviceItem(
          pairId: 'pair_revoke_test',
          deviceId: 'rec_02',
          isActive: true,
        ),
      ];

      final success = await service.revokePair('pair_revoke_test');
      expect(success, isTrue);
      expect(service.lastRevokedPairId, 'pair_revoke_test');
      expect(service.receivers.isEmpty, isTrue);
    });
  });
}
