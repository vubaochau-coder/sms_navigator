import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/constants/api_endpoints.dart';
import 'package:sms_navigator/core/network/api_client.dart';
import 'package:sms_navigator/core/services/impls/message_api_service_impl.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());

  dynamic postResponse;
  String? lastPostPath;
  dynamic lastPostBody;

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return postResponse;
  }

  dynamic getResponse;
  String? lastGetPath;
  Map<String, String>? lastGetQuery;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    lastGetQuery = queryParameters;
    return getResponse;
  }
}

void main() {
  group('MessageApiServiceImpl', () {
    test('sendMessage posts to channelMessagesV2 with request_epoch', () async {
      final fakeApi = _FakeApiClient();
      fakeApi.postResponse = <String, dynamic>{
        'success': true,
        'message_id': 'msg-123',
        'sequence_number': 42,
        'server_received_at': '2026-10-07T10:00:00.000Z',
      };

      final service = MessageApiServiceImpl(apiClient: fakeApi);
      final result = await service.sendMessage(
        channelId: 'ch-abc',
        keyEpoch: 3,
        ciphertextBase64: 'dGVzdA==',
        nonceBase64: 'bm9uY2U=',
      );

      expect(fakeApi.lastPostPath, ApiEndpoints.channelMessagesV2);
      expect(fakeApi.lastPostBody, {
        'channel_id': 'ch-abc',
        'request_epoch': 3,
        'ciphertext': 'dGVzdA==',
        'nonce': 'bm9uY2U=',
      });
      expect(result.messageId, 'msg-123');
      expect(result.sequenceNumber, 42);
    });

    test('fetchMessage GETs one message by channel + sequence (§6.4)', () async {
      final fakeApi = _FakeApiClient();
      fakeApi.getResponse = <String, dynamic>{
        'success': true,
        'message': <String, dynamic>{
          'channel_id': 'ch-abc',
          'channel_name': 'Kênh nhà',
          'sequence_number': 42,
          'key_epoch': 3,
          'ciphertext': 'Y2lwaGVy',
          'nonce': 'bm9uY2U=',
          'sender_device_id': 'owner-1',
          'sent_at': '2026-10-21T10:00:00.000Z',
          'server_received_at': '2026-10-21T10:00:00.000Z',
        },
      };

      final message = await MessageApiServiceImpl(apiClient: fakeApi)
          .fetchMessage(channelId: 'ch-abc', sequenceNumber: 42);

      expect(fakeApi.lastGetPath, ApiEndpoints.channelMessageV2);
      expect(fakeApi.lastGetQuery, {'channel_id': 'ch-abc', 'sequence_number': '42'});
      expect(message.channelName, 'Kênh nhà');
      expect(message.sequenceNumber, 42);
      expect(message.keyEpoch, 3);
      expect(message.ciphertext, 'Y2lwaGVy');
    });
  });
}
