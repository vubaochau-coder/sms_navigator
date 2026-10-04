import 'package:equatable/equatable.dart';

import '../../../../core/utils/data_converter.dart';

/// Một tin OTP của ngày — `GET /api/v2/messages?date=&tz_offset=` (§6.3).
/// Gộp OTP của TẤT CẢ kênh caller đang ACTIVE; mỗi dòng ghi rõ kênh nguồn
/// (MOBILE_FEATURES 6.2). Client decrypt ngay khi hiển thị, không lưu local.
class ChannelMessageModel extends Equatable {
  final String messageId;
  final String channelId;
  final String channelName;
  final int sequenceNumber;
  final int keyEpoch;
  final String ciphertext;
  final String nonce;
  final String senderDeviceId;
  final String sentAt;
  final String serverReceivedAt;

  /// Kết quả decrypt (không thuộc payload server).
  final String? decryptedOtp;
  final bool decryptFailed;

  const ChannelMessageModel({
    required this.messageId,
    required this.channelId,
    required this.channelName,
    required this.sequenceNumber,
    required this.keyEpoch,
    required this.ciphertext,
    required this.nonce,
    this.senderDeviceId = '',
    this.sentAt = '',
    this.serverReceivedAt = '',
    this.decryptedOtp,
    this.decryptFailed = false,
  });

  factory ChannelMessageModel.fromMap(Map<String, dynamic> map) {
    return ChannelMessageModel(
      messageId: DataConverter.cvToString(map['message_id'], '')!,
      channelId: DataConverter.cvToString(map['channel_id'], '')!,
      channelName: DataConverter.cvToString(map['channel_name'], '')!,
      sequenceNumber: DataConverter.cvToInt(map['sequence_number'], 0)!,
      keyEpoch: DataConverter.cvToInt(map['key_epoch'], 0)!,
      ciphertext: DataConverter.cvToString(map['ciphertext'], '')!,
      nonce: DataConverter.cvToString(map['nonce'], '')!,
      senderDeviceId: DataConverter.cvToString(map['sender_device_id'], '')!,
      sentAt: DataConverter.cvToString(map['sent_at'], '')!,
      serverReceivedAt: DataConverter.cvToString(map['server_received_at'], '')!,
    );
  }

  ChannelMessageModel copyWithDecrypted(String otp) => ChannelMessageModel(
    messageId: messageId,
    channelId: channelId,
    channelName: channelName,
    sequenceNumber: sequenceNumber,
    keyEpoch: keyEpoch,
    ciphertext: ciphertext,
    nonce: nonce,
    senderDeviceId: senderDeviceId,
    sentAt: sentAt,
    serverReceivedAt: serverReceivedAt,
    decryptedOtp: otp,
  );

  ChannelMessageModel copyWithDecryptFailed() => ChannelMessageModel(
    messageId: messageId,
    channelId: channelId,
    channelName: channelName,
    sequenceNumber: sequenceNumber,
    keyEpoch: keyEpoch,
    ciphertext: ciphertext,
    nonce: nonce,
    senderDeviceId: senderDeviceId,
    sentAt: sentAt,
    serverReceivedAt: serverReceivedAt,
    decryptFailed: true,
  );

  @override
  List<Object?> get props => [
    messageId,
    channelId,
    channelName,
    sequenceNumber,
    keyEpoch,
    ciphertext,
    nonce,
    senderDeviceId,
    sentAt,
    serverReceivedAt,
    decryptedOtp,
    decryptFailed,
  ];
}

/// Kết quả gửi OTP — `POST /api/v2/channels/messages` (§6.2).
class SendMessageResultModel extends Equatable {
  final String messageId;
  final int sequenceNumber;
  final String serverReceivedAt;

  const SendMessageResultModel({
    required this.messageId,
    required this.sequenceNumber,
    required this.serverReceivedAt,
  });

  factory SendMessageResultModel.fromMap(Map<String, dynamic> map) {
    return SendMessageResultModel(
      messageId: DataConverter.cvToString(map['message_id'], '')!,
      sequenceNumber: DataConverter.cvToInt(map['sequence_number'], 0)!,
      serverReceivedAt: DataConverter.cvToString(map['server_received_at'], '')!,
    );
  }

  @override
  List<Object?> get props => [messageId, sequenceNumber, serverReceivedAt];
}
