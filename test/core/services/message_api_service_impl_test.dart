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
  });
}
