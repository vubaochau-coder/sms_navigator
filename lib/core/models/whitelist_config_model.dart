import 'package:equatable/equatable.dart';

import '../enums/whitelist_mode.dart';

export '../enums/whitelist_mode.dart';

/// Một địa chỉ người gửi trong white-list.
/// [allowOtp] = false là mặc định an toàn: SMS thường được relay, OTP bị chặn.
class WhitelistEntryModel extends Equatable {
  const WhitelistEntryModel({required this.address, this.allowOtp = false});

  final String address;
  final bool allowOtp;

  WhitelistEntryModel copyWith({String? address, bool? allowOtp}) {
    return WhitelistEntryModel(
      address: address ?? this.address,
      allowOtp: allowOtp ?? this.allowOtp,
    );
  }

  Map<String, dynamic> toMap() {
    return {'address': address, 'allowOtp': allowOtp};
  }

  factory WhitelistEntryModel.fromMap(Map<String, dynamic> map) {
    return WhitelistEntryModel(
      address: (map['address'] ?? '').toString().trim(),
      allowOtp: map['allowOtp'] == true,
    );
  }

  @override
  List<Object?> get props => [address, allowOtp];
}

/// Cấu hình white-list đầy đủ: chế độ + danh sách địa chỉ.
class WhitelistConfigModel extends Equatable {
  const WhitelistConfigModel({
    this.mode = WhitelistMode.explicit,
    this.entries = const [],
  });

  final WhitelistMode mode;
  final List<WhitelistEntryModel> entries;

  bool get isEmptyList => entries.isEmpty;

  WhitelistConfigModel copyWith({
    WhitelistMode? mode,
    List<WhitelistEntryModel>? entries,
  }) {
    return WhitelistConfigModel(
      mode: mode ?? this.mode,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.nativeName,
      'entries': entries.map((entry) => entry.toMap()).toList(),
    };
  }

  factory WhitelistConfigModel.fromMap(Map<String, dynamic> map) {
    final mode = WhitelistMode.fromName(map['mode']?.toString());
    final entries = (map['entries'] as List<dynamic>? ?? const [])
        .map((item) {
          if (item is! Map) return null;
          // MethodChannel codec decode map lồng về Map<Object?, Object?> —
          // phải rebuild key về String trước khi parse.
          return WhitelistEntryModel.fromMap(Map<String, dynamic>.from(item));
        })
        .whereType<WhitelistEntryModel>()
        .where((entry) => entry.address.isNotEmpty)
        .toList();
    return WhitelistConfigModel(mode: mode, entries: entries);
  }

  @override
  List<Object?> get props => [mode, entries];
}
