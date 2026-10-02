import 'package:equatable/equatable.dart';

abstract class PairingEvent extends Equatable {
  const PairingEvent();

  @override
  List<Object?> get props => [];
}

class PairingGenerateSenderCodeEvent extends PairingEvent {
  const PairingGenerateSenderCodeEvent();
}

class PairingTimerTickedEvent extends PairingEvent {
  const PairingTimerTickedEvent();
}

class PairingSubmitReceiverQrEvent extends PairingEvent {
  final String qrData;

  const PairingSubmitReceiverQrEvent(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

/// Alias tương thích ngược: xử lý bằng cùng handler với [PairingSubmitReceiverQrEvent].
class PairingSubmitReceiverCodeEvent extends PairingSubmitReceiverQrEvent {
  const PairingSubmitReceiverCodeEvent(super.qrData);
}

class PairingCheckReceiverStatusEvent extends PairingEvent {
  const PairingCheckReceiverStatusEvent();
}

/// Timer nội bộ của bloc: kiểm tra xem Máy B đã quét mã và confirm chưa.
/// Khi đã confirm, bloc derive shared secret (qua repository) và bật relay.
class PairingSenderLinkPolled extends PairingEvent {
  const PairingSenderLinkPolled();
}

class PairingExportQrRequested extends PairingEvent {
  const PairingExportQrRequested();
}

class PairingDisconnectReceiverEvent extends PairingEvent {
  const PairingDisconnectReceiverEvent();
}
