import 'dart:async';

abstract class PairedReceiversEvent {
  const PairedReceiversEvent();
}

class PairedReceiversLoadEvent extends PairedReceiversEvent {
  final Completer<void>? completer;

  const PairedReceiversLoadEvent({this.completer});
}

class PairedReceiversToggleActiveEvent extends PairedReceiversEvent {
  final String pairId;
  final bool isActive;
  final String? displayName;

  const PairedReceiversToggleActiveEvent({
    required this.pairId,
    required this.isActive,
    this.displayName,
  });
}
