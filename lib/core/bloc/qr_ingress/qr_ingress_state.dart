import 'package:equatable/equatable.dart';

import '../../utils/qr_link_parser.dart';

/// Single-slot, one-shot pending QR (PendingIntentStore của roadmap v3.3 §3.6).
///
/// [pending] giữ link chưa được xử lý — ví dụ deeplink đến lúc Splash còn chạy;
/// [MainNavigationPage] lấy ra bằng `consume()` khi đã mounted.
/// [rejectionSeq] tăng mỗi lần một chuỗi bị từ chối, để UI hiện toast kể cả khi
/// cùng một thông điệp lặp lại.
class QrIngressState extends Equatable {
  final QrLink? pending;
  final int pendingSeq;
  final String? rejectionMessage;
  final int rejectionSeq;

  const QrIngressState({
    this.pending,
    this.pendingSeq = 0,
    this.rejectionMessage,
    this.rejectionSeq = 0,
  });

  QrIngressState copyWith({
    QrLink? pending,
    bool clearPending = false,
    int? pendingSeq,
    String? rejectionMessage,
    int? rejectionSeq,
  }) {
    return QrIngressState(
      pending: clearPending ? null : (pending ?? this.pending),
      pendingSeq: pendingSeq ?? this.pendingSeq,
      rejectionMessage: rejectionMessage ?? this.rejectionMessage,
      rejectionSeq: rejectionSeq ?? this.rejectionSeq,
    );
  }

  @override
  List<Object?> get props => [pending, pendingSeq, rejectionMessage, rejectionSeq];
}
