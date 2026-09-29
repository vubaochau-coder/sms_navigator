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

class PairingSubmitReceiverCodeEvent extends PairingEvent {
  final String code;

  const PairingSubmitReceiverCodeEvent(this.code);

  @override
  List<Object?> get props => [code];
}

class PairingCheckReceiverStatusEvent extends PairingEvent {
  const PairingCheckReceiverStatusEvent();
}

class PairingDisconnectReceiverEvent extends PairingEvent {
  const PairingDisconnectReceiverEvent();
}
