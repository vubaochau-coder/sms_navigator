import 'package:equatable/equatable.dart';

import '../../../core/models/whitelist_config_model.dart';

class WhitelistState extends Equatable {
  const WhitelistState({
    this.isLoading = false,
    this.config = const WhitelistConfigModel(),
  });

  final bool isLoading;
  final WhitelistConfigModel config;

  /// true khi cấu hình đang chặn toàn bộ SMS (EXPLICIT + danh sách trống).
  bool get blocksEverything =>
      config.mode == WhitelistMode.explicit && config.entries.isEmpty;

  WhitelistState copyWith({
    bool? isLoading,
    WhitelistConfigModel? config,
  }) {
    return WhitelistState(
      isLoading: isLoading ?? this.isLoading,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        config,
      ];
}
