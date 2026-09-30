import 'package:equatable/equatable.dart';
import '../../data/models/relay_log_model.dart';

class SenderState extends Equatable {
  final bool isLoading;
  final bool isRelayEnabled;
  final String relayMode; // 'OTP_ONLY', 'WHITELIST_ALL', 'ALL_SMS'
  final List<String> senderWhitelist;
  final bool isPaired;
  final String pairId;
  final String deviceId;
  final bool isBatteryOptimizationIgnored;
  final List<RelayLogModel> logs;
  final String? errorMessage;
  final String? lastDetectedOtp;
  final String? lastDetectedSender;

  const SenderState({
    this.isLoading = false,
    this.isRelayEnabled = false,
    this.relayMode = 'OTP_ONLY',
    this.senderWhitelist = const [],
    this.isPaired = false,
    this.pairId = '',
    this.deviceId = '',
    this.isBatteryOptimizationIgnored = false,
    this.logs = const [],
    this.errorMessage,
    this.lastDetectedOtp,
    this.lastDetectedSender,
  });

  SenderState copyWith({
    bool? isLoading,
    bool? isRelayEnabled,
    String? relayMode,
    List<String>? senderWhitelist,
    bool? isPaired,
    String? pairId,
    String? deviceId,
    bool? isBatteryOptimizationIgnored,
    List<RelayLogModel>? logs,
    String? errorMessage,
    String? lastDetectedOtp,
    String? lastDetectedSender,
  }) {
    return SenderState(
      isLoading: isLoading ?? this.isLoading,
      isRelayEnabled: isRelayEnabled ?? this.isRelayEnabled,
      relayMode: relayMode ?? this.relayMode,
      senderWhitelist: senderWhitelist ?? this.senderWhitelist,
      isPaired: isPaired ?? this.isPaired,
      pairId: pairId ?? this.pairId,
      deviceId: deviceId ?? this.deviceId,
      isBatteryOptimizationIgnored:
          isBatteryOptimizationIgnored ?? this.isBatteryOptimizationIgnored,
      logs: logs ?? this.logs,
      errorMessage: errorMessage,
      lastDetectedOtp: lastDetectedOtp ?? this.lastDetectedOtp,
      lastDetectedSender: lastDetectedSender ?? this.lastDetectedSender,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isRelayEnabled,
    relayMode,
    senderWhitelist,
    isPaired,
    pairId,
    deviceId,
    isBatteryOptimizationIgnored,
    logs,
    errorMessage,
    lastDetectedOtp,
    lastDetectedSender,
  ];
}
