import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/services/impls/native_relay_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.sms_navigator/relay');
  final service = NativeRelayServiceImpl();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NativeRelayServiceImpl whitelist bridge', () {
    test('getWhitelist parses native payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getWhitelist');
        return {
          'mode': 'ALL_ADDRESSES',
          'entries': [
            {'address': 'VCB', 'allowOtp': true},
            {'address': '+8490', 'allowOtp': false},
          ],
        };
      });

      final config = await service.getWhitelist();
      expect(config.mode, WhitelistMode.allAddresses);
      expect(config.entries.length, 2);
      expect(config.entries.first, const WhitelistEntryModel(address: 'VCB', allowOtp: true));
      expect(config.entries.last.address, '+8490');
      expect(config.entries.last.allowOtp, isFalse);
    });

    test('getWhitelist falls back to empty config on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR');
      });

      final config = await service.getWhitelist();
      expect(config, const WhitelistConfigModel());
    });

    test('setWhitelist sends mode and entries to native', () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        received = call;
        return true;
      });

      const config = WhitelistConfigModel(
        mode: WhitelistMode.explicit,
        entries: [WhitelistEntryModel(address: 'VCB', allowOtp: true)],
      );
      final success = await service.setWhitelist(config);

      expect(success, isTrue);
      expect(received!.method, 'setWhitelist');
      expect(received!.arguments, {
        'mode': 'EXPLICIT',
        'entries': [
          {'address': 'VCB', 'allowOtp': true},
        ],
      });
    });

    test('setWhitelist returns false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR');
      });

      expect(
        await service.setWhitelist(const WhitelistConfigModel()),
        isFalse,
      );
    });
  });

  group('NativeRelayServiceImpl relay config bridge', () {
    test('getRelayConfig passes through native channel config', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getRelayConfig');
        return {
          'deviceToken': 'token-1',
          'activeChannelId': 'channel-1',
          'activeChannelName': 'Kênh chính',
          'activeChannelEpoch': 2,
          'apiBaseUrl': 'https://sms-navigator-server.onrender.com',
        };
      });

      final config = await service.getRelayConfig();
      expect(config['deviceToken'], 'token-1');
      expect(config['activeChannelId'], 'channel-1');
      expect(config.containsKey('relayMode'), isFalse);
      expect(config.containsKey('senderWhitelist'), isFalse);
    });
  });
}
