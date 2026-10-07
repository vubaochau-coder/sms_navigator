import 'package:equatable/equatable.dart';

import '../enums/pairing_request_status.dart';

export '../enums/pairing_request_status.dart';
import '../utils/data_converter.dart';

PairingRequestStatus pairingRequestStatusFromRaw(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'APPROVED':
      return PairingRequestStatus.approved;
    case 'REJECTED':
      return PairingRequestStatus.rejected;
    case 'CANCELLED':
      return PairingRequestStatus.cancelled;
    default:
      return PairingRequestStatus.pending;
  }
}

/// Kết quả claim QR — `POST /api/v2/pairing/requests` (T1, API spec §5.1).
class ClaimRequestResultModel extends Equatable {
  final String requestId;
  final PairingRequestStatus status;
  final String channelId;
  final String channelName;
  final String ownerDeviceName;

  const ClaimRequestResultModel({
    required this.requestId,
    this.status = PairingRequestStatus.pending,
    required this.channelId,
    required this.channelName,
    required this.ownerDeviceName,
  });

  factory ClaimRequestResultModel.fromMap(Map<String, dynamic> map) {
    return ClaimRequestResultModel(
      requestId: DataConverter.cvToString(map['request_id'], '')!,
      status: pairingRequestStatusFromRaw(
        DataConverter.cvToString(map['status'], 'PENDING'),
      ),
      channelId: DataConverter.cvToString(map['channel_id'], '')!,
      channelName: DataConverter.cvToString(map['channel_name'], '')!,
      ownerDeviceName: DataConverter.cvToString(map['owner_device_name'], '')!,
    );
  }

  @override
  List<Object?> get props => [
    requestId,
    status,
    channelId,
    channelName,
    ownerDeviceName,
  ];
}

/// Một request trong `GET /pairing/requests/mine` (§5.2) hoặc
/// `GET /channels/requests` (hàng đợi duyệt của Owner, §5.3).
class PairingRequestModel extends Equatable {
  final String requestId;
  final String channelId;
  final String channelName;
  final String requesterDeviceId;
  final String requesterDeviceName;
  final String requesterPublicKey;
  final String ownerDeviceName;
  final PairingRequestStatus status;
  final String createdAt;
  final String? decidedAt;

  const PairingRequestModel({
    required this.requestId,
    this.channelId = '',
    this.channelName = '',
    this.requesterDeviceId = '',
    this.requesterDeviceName = '',
    this.requesterPublicKey = '',
    this.ownerDeviceName = '',
    this.status = PairingRequestStatus.pending,
    this.createdAt = '',
    this.decidedAt,
  });

  bool get isPending => status == PairingRequestStatus.pending;

  String get formattedCreatedAt {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      return '$hour:$minute · $day/$month/$year';
    } catch (_) {
      return createdAt;
    }
  }

  factory PairingRequestModel.fromMap(Map<String, dynamic> map) {
    return PairingRequestModel(
      requestId: DataConverter.cvToString(map['request_id'], '')!,
      channelId: DataConverter.cvToString(map['channel_id'], '')!,
      channelName: DataConverter.cvToString(map['channel_name'], '')!,
      requesterDeviceId:
          DataConverter.cvToString(map['requester_device_id'], '')!,
      requesterDeviceName:
          DataConverter.cvToString(map['requester_device_name'], '')!,
      requesterPublicKey:
          DataConverter.cvToString(map['requester_public_key'], '')!,
      ownerDeviceName:
          DataConverter.cvToString(map['owner_device_name'], '')!,
      status: pairingRequestStatusFromRaw(
        DataConverter.cvToString(map['status'], 'PENDING'),
      ),
      createdAt: DataConverter.cvToString(map['created_at'], '')!,
      decidedAt: DataConverter.cvToString(map['decided_at']),
    );
  }

  @override
  List<Object?> get props => [
    requestId,
    channelId,
    channelName,
    requesterDeviceId,
    requesterDeviceName,
    requesterPublicKey,
    ownerDeviceName,
    status,
    createdAt,
    decidedAt,
  ];
}
