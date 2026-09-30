import 'dart:async';

abstract class PairedSendersEvent {
  const PairedSendersEvent();
}

class PairedSendersLoadEvent extends PairedSendersEvent {
  final Completer<void>? completer;

  const PairedSendersLoadEvent({this.completer});
}

class PairedSendersRevokeEvent extends PairedSendersEvent {
  final String pairId;

  const PairedSendersRevokeEvent({required this.pairId});
}
