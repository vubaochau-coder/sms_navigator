import '../../../core/models/whitelist_config_model.dart';

abstract class WhitelistEvent {
  const WhitelistEvent();
}

class WhitelistStarted extends WhitelistEvent {
  const WhitelistStarted();
}

class WhitelistModeChanged extends WhitelistEvent {
  final WhitelistMode mode;

  const WhitelistModeChanged(this.mode);
}

class WhitelistEntryAdded extends WhitelistEvent {
  final String address;
  final bool allowOtp;

  const WhitelistEntryAdded({required this.address, this.allowOtp = false});
}

class WhitelistAllowOtpToggled extends WhitelistEvent {
  final WhitelistEntryModel entry;

  const WhitelistAllowOtpToggled(this.entry);
}

class WhitelistEntryRemoved extends WhitelistEvent {
  final WhitelistEntryModel entry;

  const WhitelistEntryRemoved(this.entry);
}
