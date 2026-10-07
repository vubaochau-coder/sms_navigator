import 'package:equatable/equatable.dart';

import '../../../core/models/whitelist_config_model.dart';

class WhitelistState extends Equatable {
  const WhitelistState({
    this.isLoading = false,
    this.config = const WhitelistConfigModel(),
    this.recentLogs = const [],
  });

  final bool isLoading;
  final WhitelistConfigModel config;

  /// Nhật ký tiếp nhận SMS từ native (mới nhất trước, tối đa 30 entry).
  final List<Map<String, dynamic>> recentLogs;

  /// true khi cấu hình đang chặn toàn bộ SMS (EXPLICIT + danh sách trống).
  bool get blocksEverything =>
      config.mode == WhitelistMode.explicit && config.entries.isEmpty;

  WhitelistState copyWith({
    bool? isLoading,
    WhitelistConfigModel? config,
    List<Map<String, dynamic>>? recentLogs,
  }) {
    return WhitelistState(
      isLoading: isLoading ?? this.isLoading,
      config: config ?? this.config,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        config,
        recentLogs,
      ];
}
