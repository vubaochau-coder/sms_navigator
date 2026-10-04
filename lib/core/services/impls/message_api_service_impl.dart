import '../../constants/api_endpoints.dart';
import '../../models/channel_message_model.dart';
import '../../network/api_client.dart';
import '../../utils/data_converter.dart';
import '../message_api_service.dart';

class MessageApiServiceImpl implements MessageApiService {
  MessageApiServiceImpl({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _asMap(dynamic data) =>
      DataConverter.cvToMap<String, dynamic>(data) ?? <String, dynamic>{};

  List<Map<String, dynamic>> _asListOfMaps(dynamic raw) =>
      DataConverter.cvToList<Map<String, dynamic>>(
        raw,
        (item) => _asMap(item),
      );

  @override
  Future<SendMessageResultModel> sendMessage({
    required String channelId,
    required int keyEpoch,
    required String ciphertextBase64,
    required String nonceBase64,
  }) async {
    final body = <String, dynamic>{
      'channel_id': channelId,
      'key_epoch': keyEpoch,
      'ciphertext': ciphertextBase64,
      'nonce': nonceBase64,
    };
    final res = await apiClient.post(ApiEndpoints.channelMessagesV2, body: body);
    return SendMessageResultModel.fromMap(_asMap(res));
  }

  @override
  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchMessagesByDate({
    required String date,
    int tzOffset = 0,
  }) async {
    final res = await apiClient.get(
      ApiEndpoints.messagesByDateV2,
      queryParameters: <String, String>{
        'date': date,
        'tz_offset': tzOffset.toString(),
      },
    );
    final map = _asMap(res);
    final list = _asListOfMaps(map['messages']);
    final messages = list.map(ChannelMessageModel.fromMap).toList();
    final truncated = map['truncated'] == true;
    return (messages: messages, truncated: truncated);
  }
}
