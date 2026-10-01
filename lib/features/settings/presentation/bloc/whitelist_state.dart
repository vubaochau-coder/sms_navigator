import 'package:equatable/equatable.dart';

import '../../../sender/data/models/whitelist_config_model.dart';

class WhitelistState extends Equatable {
  const WhitelistState({
    this.isLoading = false,
    this.config = const WhitelistConfigModel(),
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final WhitelistConfigModel config;
  final String? errorMessage;
  final String? successMessage;

  /// true khi cấu hình đang chặn toàn bộ SMS (EXPLICIT + danh sách trống).
  bool get blocksEverything =>
      config.mode == WhitelistMode.explicit && config.entries.isEmpty;

  WhitelistState copyWith({
    bool? isLoading,
    WhitelistConfigModel? config,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WhitelistState(
      isLoading: isLoading ?? this.isLoading,
      config: config ?? this.config,
      errorMessage: clearError ? null : errorMessage,
      successMessage: clearSuccess ? null : successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        config,
        errorMessage,
        successMessage,
      ];
}
