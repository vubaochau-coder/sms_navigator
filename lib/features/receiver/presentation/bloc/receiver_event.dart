import 'package:equatable/equatable.dart';
import '../../data/models/received_otp_model.dart';

abstract class ReceiverEvent extends Equatable {
  const ReceiverEvent();

  @override
  List<Object?> get props => [];
}

class ReceiverLoadOtpsEvent extends ReceiverEvent {
  const ReceiverLoadOtpsEvent();
}

class ReceiverStartSyncEvent extends ReceiverEvent {
  const ReceiverStartSyncEvent();
}

class ReceiverStopSyncEvent extends ReceiverEvent {
  const ReceiverStopSyncEvent();
}

class ReceiverNewOtpPushedEvent extends ReceiverEvent {
  final ReceivedOtpModel otp;

  const ReceiverNewOtpPushedEvent(this.otp);

  @override
  List<Object?> get props => [otp];
}

class ReceiverClearHistoryEvent extends ReceiverEvent {
  const ReceiverClearHistoryEvent();
}

class ReceiverPollPendingOtpsEvent extends ReceiverEvent {
  const ReceiverPollPendingOtpsEvent();
}
