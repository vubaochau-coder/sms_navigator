import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/sender/data/models/whitelist_config_model.dart';
import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';

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
    test('getRelayConfig no longer exposes legacy whitelist fields',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getRelayConfig');
        return {
          'isRelayEnabled': true,
          'pairId': 'pair-123',
          'sharedSecretBase64': 'secret',
          'relayUrl': 'https://example.com/relay',
          'deviceId': 'device-1',
          'deviceToken': 'token-1',
        };
      });

      final config = await service.getRelayConfig();
      expect(config['pairId'], 'pair-123');
      expect(config.containsKey('relayMode'), isFalse);
      expect(config.containsKey('senderWhitelist'), isFalse);
    });

    test('setRelayConfig sends only relay fields', () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        received = call;
        return true;
      });

      final success = await service.setRelayConfig(
        isRelayEnabled: true,
        pairId: 'pair-123',
        sharedSecretBase64: 'secret',
      );

      expect(success, isTrue);
      expect(received!.arguments, {
        'isRelayEnabled': true,
        'pairId': 'pair-123',
        'sharedSecretBase64': 'secret',
      });
    });
  });
}
