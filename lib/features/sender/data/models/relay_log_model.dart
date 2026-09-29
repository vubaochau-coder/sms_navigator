import 'package:equatable/equatable.dart';

class RelayLogModel extends Equatable {
  final String id;
  final String sender;
  final String otp;
  final String status;
  final String error;
  final int timestamp;

  const RelayLogModel({
    required this.id,
    required this.sender,
    required this.otp,
    required this.status,
    this.error = '',
    required this.timestamp,
  });

  RelayLogModel copyWith({
    String? id,
    String? sender,
    String? otp,
    String? status,
    String? error,
    int? timestamp,
  }) {
    return RelayLogModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      otp: otp ?? this.otp,
      status: status ?? this.status,
      error: error ?? this.error,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'otp': otp,
      'status': status,
      'error': error,
      'timestamp': timestamp,
    };
  }

  factory RelayLogModel.fromMap(Map<String, dynamic> map) {
    return RelayLogModel(
      id: map['id']?.toString() ?? '',
      sender: map['sender']?.toString() ?? 'Unknown',
      otp: map['otp']?.toString() ?? '',
      status: map['status']?.toString() ?? 'PENDING',
      error: map['error']?.toString() ?? '',
      timestamp: (map['timestamp'] is num) ? (map['timestamp'] as num).toInt() : 0,
    );
  }

  @override
  List<Object?> get props => [id, sender, otp, status, error, timestamp];
}
