import 'dart:async';

abstract class PairedSendersEvent {
  const PairedSendersEvent();
}

class PairedSendersLoadEvent extends PairedSendersEvent {
  final Completer<void>? completer;

  const PairedSendersLoadEvent({this.completer});
}
