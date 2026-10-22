import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Trạng thái một SMS trong nhật ký relay native (`OtpPreferences.addRelayLog`).
enum RelayLogStatus {
  success,
  enqueued,
  retrying,
  parked,
  failed,
  blocked,
  skipped,
  unknown;

  static RelayLogStatus fromWire(String? raw) => switch (raw) {
    'SUCCESS' => RelayLogStatus.success,
    'ENQUEUED' => RelayLogStatus.enqueued,
    'RETRYING' => RelayLogStatus.retrying,
    'PARKED' => RelayLogStatus.parked,
    'FAILED' => RelayLogStatus.failed,
    'BLOCKED' => RelayLogStatus.blocked,
    'SKIPPED' => RelayLogStatus.skipped,
    _ => RelayLogStatus.unknown,
  };
}

/// Một dòng nhật ký tiếp nhận / chuyển tiếp SMS trên máy relay.
class RelayLogEntry extends Equatable {
  const RelayLogEntry({
    required this.id,
    required this.sender,
    required this.status,
    this.detected = '',
    this.detail = '',
    this.at,
  });

  factory RelayLogEntry.fromMap(Map<String, dynamic> map) {
    final at = DataConverter.cvToDateTime(map['timestamp']);
    return RelayLogEntry(
      id: DataConverter.cvToString(map['id'], '')!,
      sender: DataConverter.cvToString(map['sender'], '')!,
      status: RelayLogStatus.fromWire(DataConverter.cvToString(map['status'])),
      detected: DataConverter.cvToString(map['otp'], '')!,
      detail: DataConverter.cvToString(map['error'], '')!,
      at: at != null && at.millisecondsSinceEpoch > 0 ? at : null,
    );
  }

  final String id;
  final String sender;
  final RelayLogStatus status;

  /// OTP đã che (`1***9`) hoặc `SMS` cho tin thường; rỗng nếu chưa đọc tới.
  final String detected;

  /// Lý do / chi tiết (kênh đích, lỗi…).
  final String detail;
  final DateTime? at;

  @override
  List<Object?> get props => [id, sender, status, detected, detail, at];
}
