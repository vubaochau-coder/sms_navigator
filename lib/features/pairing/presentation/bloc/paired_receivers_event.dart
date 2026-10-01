import 'dart:async';

abstract class PairedReceiversEvent {
  const PairedReceiversEvent();
}

class PairedReceiversLoadEvent extends PairedReceiversEvent {
  final Completer<void>? completer;

  const PairedReceiversLoadEvent({this.completer});
}
