import 'package:equatable/equatable.dart';

abstract class SenderEvent extends Equatable {
  const SenderEvent();

  @override
  List<Object?> get props => [];
}

class SenderLoadStatusEvent extends SenderEvent {
  const SenderLoadStatusEvent();
}

class SenderToggleRelayEvent extends SenderEvent {
  final bool isEnabled;

  const SenderToggleRelayEvent(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

class SenderRequestBatteryOptimizationEvent extends SenderEvent {
  const SenderRequestBatteryOptimizationEvent();
}

class SenderUnpairEvent extends SenderEvent {
  const SenderUnpairEvent();
}

class SenderOtpDetectedEvent extends SenderEvent {
  final String sender;
  final String otp;

  const SenderOtpDetectedEvent(this.sender, this.otp);

  @override
  List<Object?> get props => [sender, otp];
}

class SenderUpdateRelayModeEvent extends SenderEvent {
  final String relayMode;

  const SenderUpdateRelayModeEvent(this.relayMode);

  @override
  List<Object?> get props => [relayMode];
}

class SenderAddWhitelistPrefixEvent extends SenderEvent {
  final String prefix;

  const SenderAddWhitelistPrefixEvent(this.prefix);

  @override
  List<Object?> get props => [prefix];
}

class SenderRemoveWhitelistPrefixEvent extends SenderEvent {
  final String prefix;

  const SenderRemoveWhitelistPrefixEvent(this.prefix);

  @override
  List<Object?> get props => [prefix];
}
