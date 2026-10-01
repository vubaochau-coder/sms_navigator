import '../../../../core/utils/data_converter.dart';

class RelayHistoryItemModel {
  final String id;
  final String pairId;
  final String senderDeviceId;
  final String? senderDeviceName;
  final String? receiverDeviceName;
  final String? viewerRole;
  final String encryptedPayload;
  final String iv;
  final DateTime? sentAt;
  final DateTime? relayedAt;
  final String status;
  final String? messageId;

  const RelayHistoryItemModel({
    required this.id,
    required this.pairId,
    required this.senderDeviceId,
    this.senderDeviceName,
    this.receiverDeviceName,
    this.viewerRole,
    required this.encryptedPayload,
    required this.iv,
    this.sentAt,
    this.relayedAt,
    this.status = 'SUCCESS',
    this.messageId,
  });

  factory RelayHistoryItemModel.fromMap(Map<String, dynamic> map) {
    return RelayHistoryItemModel(
      id: DataConverter.cvToString(map['id'], '')!,
      pairId: DataConverter.cvToString(map['pair_id'], '')!,
      senderDeviceId: DataConverter.cvToString(map['sender_device_id'], '')!,
      senderDeviceName: DataConverter.cvToString(map['sender_device_name']),
      receiverDeviceName: DataConverter.cvToString(map['receiver_device_name']),
      viewerRole: DataConverter.cvToString(map['viewer_role']),
      encryptedPayload: DataConverter.cvToString(map['encrypted_payload'], '')!,
      iv: DataConverter.cvToString(map['iv'], '')!,
      sentAt: DataConverter.cvToDateTime(map['sent_at']),
      relayedAt: DataConverter.cvToDateTime(map['relayed_at']),
      status: DataConverter.cvToString(map['status'], 'SUCCESS')!,
      messageId: DataConverter.cvToString(map['message_id']),
    );
  }
}
