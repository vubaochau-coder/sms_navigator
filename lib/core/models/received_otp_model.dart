import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

class ReceivedOtpModel extends Equatable {
  final String id;
  final String sender;
  final String otp;
  final int receivedAt;
  final int expiresAt;

  /// Nội dung SMS gốc (full message) gửi kèm từ Máy Gửi (nếu có).
  final String rawMessage;

  const ReceivedOtpModel({
    required this.id,
    required this.sender,
    required this.otp,
    required this.receivedAt,
    required this.expiresAt,
    this.rawMessage = '',
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  int get remainingSeconds {
    final diff = expiresAt - DateTime.now().millisecondsSinceEpoch;
    return diff > 0 ? (diff / 1000).floor() : 0;
  }

  ReceivedOtpModel copyWith({
    String? id,
    String? sender,
    String? otp,
    int? receivedAt,
    int? expiresAt,
    String? rawMessage,
  }) {
    return ReceivedOtpModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      otp: otp ?? this.otp,
      receivedAt: receivedAt ?? this.receivedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rawMessage: rawMessage ?? this.rawMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'otp': otp,
      'receivedAt': receivedAt,
      'expiresAt': expiresAt,
      'rawMessage': rawMessage,
    };
  }

  factory ReceivedOtpModel.fromMap(Map<String, dynamic> map) {
    return ReceivedOtpModel(
      id: DataConverter.cvToString(map['id'], '')!,
      sender: DataConverter.cvToString(map['sender'], 'Unknown')!,
      otp: DataConverter.cvToString(map['otp'], '')!,
      receivedAt: DataConverter.cvToInt(map['receivedAt'], 0)!,
      expiresAt: DataConverter.cvToInt(map['expiresAt'], 0)!,
      rawMessage: DataConverter.cvToString(map['rawMessage'], '')!,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sender,
    otp,
    receivedAt,
    expiresAt,
    rawMessage,
  ];
}
