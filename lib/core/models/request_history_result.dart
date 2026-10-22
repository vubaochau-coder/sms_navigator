import 'package:equatable/equatable.dart';

import 'pairing_request_model.dart';

/// Một trang `GET /channels/requests?status=HISTORY` (BACKLOG 1.6):
/// request đã xử lý, mới nhất trước; [nextBefore] null = hết.
class RequestHistoryResult extends Equatable {
  final List<PairingRequestModel> items;
  final String? nextBefore;

  const RequestHistoryResult({this.items = const [], this.nextBefore});

  bool get hasMore => nextBefore != null;

  @override
  List<Object?> get props => [items, nextBefore];
}
