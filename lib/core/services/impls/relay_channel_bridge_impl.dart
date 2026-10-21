import 'package:flutter/services.dart';

import '../../utils/app_logger.dart';
import '../relay_channel_bridge.dart';

class RelayChannelBridgeImpl implements RelayChannelBridge {
  RelayChannelBridgeImpl({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.example.sms_navigator/relay');

  final MethodChannel _channel;

  @override
  Future<void> setCredentials({
    required String deviceToken,
    String? apiBaseUrl,
  }) async {
    await _invoke<bool>('setRelayCredentials', {
      'deviceToken': deviceToken,
      if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) 'apiBaseUrl': apiBaseUrl,
    });
  }

  @override
  Future<int> replaceRelayChannels(
    List<RelayChannelSnapshot> channels, {
    List<String> retainChannelIds = const [],
  }) async {
    final result = await _invoke<int>('replaceRelayChannels', {
      'channels': channels.map((c) => c.toMap()).toList(),
      'retainChannelIds': retainChannelIds,
    });
    return result ?? 0;
  }

  @override
  Future<void> stageKey({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    String? channelName,
  }) async {
    await _invoke<bool>('stageRelayKey', {
      'channelId': channelId,
      'keyEpoch': keyEpoch,
      'channelKeyBase64': channelKeyBase64,
      'channelName': ?channelName,
    });
  }

  @override
  Future<bool> promoteKey({
    required String channelId,
    required int keyEpoch,
  }) async {
    final result = await _invoke<bool>('promoteRelayKey', {
      'channelId': channelId,
      'keyEpoch': keyEpoch,
    });
    return result ?? false;
  }

  @override
  Future<void> discardKey({
    required String channelId,
    required int keyEpoch,
  }) async {
    await _invoke<bool>('discardRelayKey', {
      'channelId': channelId,
      'keyEpoch': keyEpoch,
    });
  }

  @override
  Future<int> flushParkedMessages() async {
    final result = await _invoke<int>('flushParkedMessages');
    return result ?? 0;
  }

  /// Native relay is Android-only and best-effort from Dart's point of view:
  /// a missing plugin (iOS, widget tests) must never break the caller.
  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      AppLogger.w('RelayChannelBridge', '$method failed: ${e.code} ${e.message}');
      return null;
    }
  }
}
