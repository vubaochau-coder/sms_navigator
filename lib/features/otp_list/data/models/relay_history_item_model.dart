class RelayHistoryItemModel {
  final String id;
  final String pairId;
  final String senderDeviceId;
  final String? senderDeviceName;
  final String encryptedPayload;
  final String iv;
  final int sentAt;
  final int relayedAt;
  final String status;
  final String? messageId;

  const RelayHistoryItemModel({
    required this.id,
    required this.pairId,
    required this.senderDeviceId,
    this.senderDeviceName,
    required this.encryptedPayload,
    required this.iv,
    required this.sentAt,
    required this.relayedAt,
    this.status = 'SUCCESS',
    this.messageId,
  });

  factory RelayHistoryItemModel.fromMap(Map<String, dynamic> map) {
    return RelayHistoryItemModel(
      id: map['id']?.toString() ?? '',
      pairId: map['pair_id']?.toString() ?? '',
      senderDeviceId: map['sender_device_id']?.toString() ?? '',
      senderDeviceName: map['sender_device_name']?.toString(),
      encryptedPayload: map['encrypted_payload']?.toString() ?? '',
      iv: map['iv']?.toString() ?? '',
      sentAt: (map['sent_at'] as num?)?.toInt() ?? 0,
      relayedAt: (map['relayed_at'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'SUCCESS',
      messageId: map['message_id']?.toString(),
    );
  }
}
