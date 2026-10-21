import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/services/impls/relay_channel_bridge_impl.dart';
import 'package:sms_navigator/core/services/relay_channel_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.sms_navigator/relay');
  final bridge = RelayChannelBridgeImpl();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'replaceRelayChannels':
          return (call.arguments['channels'] as List).length;
        case 'promoteRelayKey':
          return true;
        case 'flushParkedMessages':
          return 3;
        default:
          return true;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('replaceRelayChannels sends every channel plus the retain list', () async {
    final count = await bridge.replaceRelayChannels(
      const [
        RelayChannelSnapshot(channelId: 'a', channelName: 'A', keyEpoch: 2, channelKeyBase64: 'ka'),
        RelayChannelSnapshot(channelId: 'b', channelName: 'B', keyEpoch: 1, channelKeyBase64: 'kb'),
      ],
      retainChannelIds: const ['c'],
    );

    expect(count, 2);
    expect(calls.single.method, 'replaceRelayChannels');
    expect(calls.single.arguments, {
      'channels': [
        {'channelId': 'a', 'channelName': 'A', 'keyEpoch': 2, 'channelKeyBase64': 'ka'},
        {'channelId': 'b', 'channelName': 'B', 'keyEpoch': 1, 'channelKeyBase64': 'kb'},
      ],
      'retainChannelIds': ['c'],
    });
  });

  test('stage → promote → discard map to the native methods', () async {
    await bridge.stageKey(channelId: 'a', keyEpoch: 3, channelKeyBase64: 'k3', channelName: 'A');
    final promoted = await bridge.promoteKey(channelId: 'a', keyEpoch: 3);
    await bridge.discardKey(channelId: 'a', keyEpoch: 4);

    expect(promoted, isTrue);
    expect(calls.map((c) => c.method), ['stageRelayKey', 'promoteRelayKey', 'discardRelayKey']);
    expect(calls.first.arguments, {
      'channelId': 'a',
      'keyEpoch': 3,
      'channelKeyBase64': 'k3',
      'channelName': 'A',
    });
  });

  test('flushParkedMessages returns the native count', () async {
    expect(await bridge.flushParkedMessages(), 3);
  });

  test('platform errors never escape the bridge', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'ERR'));

    expect(await bridge.promoteKey(channelId: 'a', keyEpoch: 1), isFalse);
    expect(await bridge.flushParkedMessages(), 0);
  });
}
