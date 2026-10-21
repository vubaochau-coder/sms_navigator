import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/core/repositories/impls/sms_by_date_repository_impl.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/message_api_service.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';

class _KeyStore implements ChannelKeyStore {
  final Map<String, String> keys = {};
  int reads = 0;

  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async {
    reads++;
    return keys['$channelId#$epoch'];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _MessageApi implements MessageApiService {
  List<ChannelMessageModel> messages = [];

  @override
  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchMessagesByDate({
    required String date,
    int tzOffset = 0,
    CancelToken? cancelToken,
  }) async => (messages: messages, truncated: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  final crypto = ChannelCryptoHelper();
  late _KeyStore keyStore;
  late _MessageApi api;
  late SmsByDateRepositoryImpl repo;

  setUp(() {
    keyStore = _KeyStore();
    api = _MessageApi();
    repo = SmsByDateRepositoryImpl(messageApiService: api, keyStore: keyStore, cryptoHelper: crypto);
  });

  Future<ChannelMessageModel> encrypted(String channelId, int epoch, int seq, String text) async {
    final enc = await crypto.encryptMessage(
      plaintext: text,
      channelKeyBase64: keyStore.keys['$channelId#$epoch']!,
      channelId: channelId,
      keyEpoch: epoch,
    );
    return ChannelMessageModel(
      messageId: 'm$seq',
      channelId: channelId,
      channelName: 'Kênh $channelId',
      sequenceNumber: seq,
      keyEpoch: epoch,
      ciphertext: enc.ciphertextBase64,
      nonce: enc.nonceBase64,
    );
  }

  test('reads each (channel, epoch) key once and keeps message order (isolate batch)', () async {
    keyStore.keys['a#1'] = crypto.generateChannelKeyBase64();
    keyStore.keys['b#2'] = crypto.generateChannelKeyBase64();
    final messages = <ChannelMessageModel>[];
    for (var i = 0; i < 40; i++) {
      messages.add(await encrypted(i.isEven ? 'a' : 'b', i.isEven ? 1 : 2, i, 'OTP $i'));
    }
    api.messages = messages;

    final result = await repo.fetchByDate(date: DateTime(2026, 10, 21));

    expect(keyStore.reads, 2);
    expect(result.messages.map((m) => m.messageId), messages.map((m) => m.messageId));
    expect(result.messages.every((m) => !m.decryptFailed), isTrue);
    expect(result.messages[7].decryptedOtp, contains('7'));
  });

  test('missing key or tampered ciphertext marks only that message as failed', () async {
    keyStore.keys['a#1'] = crypto.generateChannelKeyBase64();
    final ok = await encrypted('a', 1, 1, 'OTP 123456');
    final tampered = ChannelMessageModel(
      messageId: 'bad',
      channelId: 'a',
      channelName: 'Kênh a',
      sequenceNumber: 2,
      keyEpoch: 1,
      ciphertext: ok.ciphertext.replaceRange(0, 4, 'AAAA'),
      nonce: ok.nonce,
    );
    const noKey = ChannelMessageModel(
      messageId: 'nokey',
      channelId: 'z',
      channelName: 'Kênh z',
      sequenceNumber: 3,
      keyEpoch: 9,
      ciphertext: 'AAAA',
      nonce: 'AAAAAAAAAAAAAAAA',
    );
    api.messages = [ok, tampered, noKey];

    final result = await repo.fetchByDate(date: DateTime(2026, 10, 21));

    expect(result.messages[0].decryptFailed, isFalse);
    expect(result.messages[1].decryptFailed, isTrue);
    expect(result.messages[2].decryptFailed, isTrue);
  });
}
