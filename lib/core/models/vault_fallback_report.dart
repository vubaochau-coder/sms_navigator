import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Native đã phải lưu dữ liệu nhạy cảm **thô** vì Android Keystore lỗi
/// (BACKLOG 2.2) — [count] lần kể từ báo cáo trước, lần cuối ở [site].
class VaultFallbackReport extends Equatable {
  const VaultFallbackReport({required this.count, this.site = '', this.error = '', this.at});

  final int count;
  final String site;
  final String error;
  final DateTime? at;

  static VaultFallbackReport? fromMap(Map<String, dynamic>? map) {
    final count = DataConverter.cvToInt(map?['count'], 0)!;
    if (map == null || count <= 0) return null;
    final atMs = DataConverter.cvToInt(map['at'], 0)!;
    return VaultFallbackReport(
      count: count,
      site: DataConverter.cvToString(map['site'], '')!,
      error: DataConverter.cvToString(map['error'], '')!,
      at: atMs > 0 ? DateTime.fromMillisecondsSinceEpoch(atMs) : null,
    );
  }

  @override
  List<Object?> get props => [count, site, error, at];
}
