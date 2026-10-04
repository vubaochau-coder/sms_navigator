import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Một tin SMS / OTP của ngày — `GET /api/v2/messages?date=&tz_offset=` (§6.3).
/// Gộp SMS/OTP của TẤT CẢ kênh caller đang ACTIVE; mỗi dòng ghi rõ kênh nguồn
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

  /// Đầu số / Brandname gửi tin gốc (ví dụ: "VCB", "Techcombank", "+8491...").
  final String? sender;

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
    this.sender,
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
      sender: DataConverter.cvToString(map['sender']),
    );
  }

  ChannelMessageModel copyWithDecrypted(String otp) {
    String? extractedSender;
    String cleanOtp = otp;
    final trimmed = otp.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
        extractedSender = DataConverter.cvToString(parsed['sender']);
        cleanOtp = DataConverter.cvToString(
              parsed['fullMessage'] ?? parsed['otp'],
            ) ??
            cleanOtp;
      } catch (_) {}
    }

    return ChannelMessageModel(
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
      sender: extractedSender ?? sender,
      decryptedOtp: cleanOtp,
    );
  }

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
    sender: sender,
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
    sender,
    decryptedOtp,
    decryptFailed,
  ];
}

/// Kết quả gửi OTP/SMS — `POST /api/v2/channels/messages` (§6.2).
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
