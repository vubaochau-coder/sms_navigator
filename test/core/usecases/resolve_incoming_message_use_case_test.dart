import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/message_api_service.dart';
import 'package:sms_navigator/core/usecases/resolve_incoming_message_use_case.dart';
import 'package:sms_navigator/core/usecases/sync_channel_keys_use_case.dart';

class _MessageApi implements MessageApiService {
  ChannelMessageModel? message;
  Object? error;
  final List<(String, int)> calls = [];

  @override
  Future<ChannelMessageModel> fetchMessage({
    required String channelId,
    required int sequenceNumber,
    CancelToken? cancelToken,
  }) async {
    calls.add((channelId, sequenceNumber));
    if (error != null) throw error!;
    return message!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _KeyStore implements ChannelKeyStore {
  final Map<String, String> keys = {};

  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async =>
      keys['$channelId#$epoch'];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

/// Giả lập server có envelope của epoch còn thiếu.
class _Sync implements SyncChannelKeysUseCase {
  _Sync(this.keyStore);
  final _KeyStore keyStore;
  final Map<String, String> provides = {};
  final List<String?> calls = [];

  @override
  Future<ChannelKeySyncResult> call({String? channelId}) async {
    calls.add(channelId);
    keyStore.keys.addAll(provides);
    return ChannelKeySyncResult(added: provides.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  final crypto = ChannelCryptoHelper();
  late _MessageApi api;
  late _KeyStore keyStore;
  late ResolveIncomingMessageUseCase resolve;
  late String key;

  Future<ChannelMessageModel> encrypted(String plaintext, {int epoch = 2}) async {
    final sealed = await crypto.encryptMessage(
      plaintext: plaintext,
      channelKeyBase64: key,
      channelId: 'ch-1',
      keyEpoch: epoch,
      // Đúng như OtpRelayWorker: mã hoá trước khi server cấp sequence → hint 0.
    );
    return ChannelMessageModel(
      messageId: '',
      channelId: 'ch-1',
      channelName: 'Kênh nhà',
      sequenceNumber: 9,
      keyEpoch: epoch,
      ciphertext: sealed.ciphertextBase64,
      nonce: sealed.nonceBase64,
    );
  }

  setUp(() {
    api = _MessageApi();
    keyStore = _KeyStore();
    key = crypto.generateChannelKeyBase64();
    keyStore.keys['ch-1#2'] = key;
    resolve = ResolveIncomingMessageUseCase(
      messageApiService: api,
      keyStore: keyStore,
      cryptoHelper: crypto,
    );
  });

  test('decrypts a message the Owner sealed before the server assigned sequence 9', () async {
    api.message = await encrypted(jsonEncode({'sender': 'VCB', 'fullMessage': 'Ma OTP 482913'}));

    final result = await resolve(channelId: 'ch-1', sequenceNumber: 9);

    expect(api.calls, [('ch-1', 9)]);
    expect(result.decryptFailed, isFalse);
    expect(result.sender, 'VCB');
    expect(result.decryptedOtp, 'Ma OTP 482913');
  });

  test('missing key for the epoch → decryptFailed', () async {
    api.message = await encrypted('x', epoch: 5);
    final result = await resolve(channelId: 'ch-1', sequenceNumber: 9);
    expect(result.decryptFailed, isTrue);
    expect(result.decryptedOtp, isNull);
  });

  test('wrong key → decryptFailed (never throws)', () async {
    api.message = await encrypted('x');
    keyStore.keys['ch-1#2'] = crypto.generateChannelKeyBase64();
    final result = await resolve(channelId: 'ch-1', sequenceNumber: 9);
    expect(result.decryptFailed, isTrue);
  });

  test('network errors propagate so the caller can fall back', () async {
    api.error = Exception('offline');
    await expectLater(resolve(channelId: 'ch-1', sequenceNumber: 9), throwsException);
  });

  test('missing key for the epoch → syncs that channel once, then decrypts (FLOW_AUDIT K2)', () async {
    api.message = await encrypted('Ma OTP 482913', epoch: 5); // channel rotated to 5, app not opened yet
    final sync = _Sync(keyStore)..provides['ch-1#5'] = key;
    final healing = ResolveIncomingMessageUseCase(
      messageApiService: api,
      keyStore: keyStore,
      cryptoHelper: crypto,
      syncChannelKeys: sync,
    );

    final result = await healing(channelId: 'ch-1', sequenceNumber: 9);

    expect(sync.calls, ['ch-1']);
    expect(result.decryptFailed, isFalse);
    expect(result.decryptedOtp, 'Ma OTP 482913');
  });

  test('key sync that brings nothing → decryptFailed, no throw', () async {
    api.message = await encrypted('x', epoch: 7);
    final sync = _Sync(keyStore);
    final healing = ResolveIncomingMessageUseCase(
      messageApiService: api,
      keyStore: keyStore,
      cryptoHelper: crypto,
      syncChannelKeys: sync,
    );

    expect((await healing(channelId: 'ch-1', sequenceNumber: 9)).decryptFailed, isTrue);
    expect(sync.calls, hasLength(1));
  });
}
