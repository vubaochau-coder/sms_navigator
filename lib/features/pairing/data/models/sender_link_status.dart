import 'package:equatable/equatable.dart';

/// Kết quả kiểm tra trạng thái liên kết phía Máy A (sender).
///
/// Máy A poll `/pair/status` định kỳ: khi Máy B đã confirm và máy chủ trả về
/// `receiver_pubkey`, Máy A derive shared secret và kích hoạt relay.
class SenderLinkStatus extends Equatable {
  final bool linked;
  final String? receiverDeviceName;

  const SenderLinkStatus({required this.linked, this.receiverDeviceName});

  static const SenderLinkStatus waiting = SenderLinkStatus(linked: false);

  @override
  List<Object?> get props => [linked, receiverDeviceName];
}
