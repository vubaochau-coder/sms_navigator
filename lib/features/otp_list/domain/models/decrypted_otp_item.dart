import 'package:equatable/equatable.dart';

class DecryptedOtpItem extends Equatable {
  final String id;
  final String pairId;
  final String senderDeviceId;
  final String senderDeviceName;
  final String sender; // e.g. Vietcombank, Viettel, 招商银行
  final String otp;
  final String fullMessage;
  final DateTime receivedAt;
  final DateTime? sentAt;
  final String status;

  const DecryptedOtpItem({
    required this.id,
    required this.pairId,
    required this.senderDeviceId,
    required this.senderDeviceName,
    required this.sender,
    required this.otp,
    required this.fullMessage,
    required this.receivedAt,
    this.sentAt,
    this.status = 'SUCCESS',
  });

  @override
  List<Object?> get props => [
    id,
    pairId,
    senderDeviceId,
    senderDeviceName,
    sender,
    otp,
    fullMessage,
    receivedAt,
    sentAt,
    status,
  ];
}
