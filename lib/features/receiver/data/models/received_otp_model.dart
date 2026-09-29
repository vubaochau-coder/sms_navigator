import 'package:equatable/equatable.dart';

class ReceivedOtpModel extends Equatable {
  final String id;
  final String sender;
  final String otp;
  final int receivedAt;
  final int expiresAt;

  const ReceivedOtpModel({
    required this.id,
    required this.sender,
    required this.otp,
    required this.receivedAt,
    required this.expiresAt,
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
  }) {
    return ReceivedOtpModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      otp: otp ?? this.otp,
      receivedAt: receivedAt ?? this.receivedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'otp': otp,
      'receivedAt': receivedAt,
      'expiresAt': expiresAt,
    };
  }

  factory ReceivedOtpModel.fromMap(Map<String, dynamic> map) {
    return ReceivedOtpModel(
      id: map['id']?.toString() ?? '',
      sender: map['sender']?.toString() ?? 'Unknown',
      otp: map['otp']?.toString() ?? '',
      receivedAt: (map['receivedAt'] is num) ? (map['receivedAt'] as num).toInt() : 0,
      expiresAt: (map['expiresAt'] is num) ? (map['expiresAt'] as num).toInt() : 0,
    );
  }

  @override
  List<Object?> get props => [id, sender, otp, receivedAt, expiresAt];
}
