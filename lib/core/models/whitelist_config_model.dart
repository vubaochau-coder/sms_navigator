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

  Map<String, dynamic> toJson() {
    return {'address': address, 'allow_otp': allowOtp};
  }

  factory WhitelistEntryModel.fromMap(Map<String, dynamic> map) {
    return WhitelistEntryModel(
      address: (map['address'] ?? '').toString().trim(),
      allowOtp: map['allowOtp'] == true || map['allow_otp'] == true,
    );
  }

  factory WhitelistEntryModel.fromJson(Map<String, dynamic> json) =>
      WhitelistEntryModel.fromMap(json);

  @override
  List<Object?> get props => [address, allowOtp];
}

/// Cấu hình white-list đầy đủ: chế độ + danh sách địa chỉ + phiên bản xung đột.
class WhitelistConfigModel extends Equatable {
  const WhitelistConfigModel({
    this.mode = WhitelistMode.explicit,
    this.entries = const [],
    this.version = 1,
  });

  final WhitelistMode mode;
  final List<WhitelistEntryModel> entries;
  final int version;

  bool get isEmptyList => entries.isEmpty;

  WhitelistConfigModel copyWith({
    WhitelistMode? mode,
    List<WhitelistEntryModel>? entries,
    int? version,
  }) {
    return WhitelistConfigModel(
      mode: mode ?? this.mode,
      entries: entries ?? this.entries,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.nativeName,
      'entries': entries.map((entry) => entry.toMap()).toList(),
      'version': version,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.nativeName,
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'version': version,
    };
  }

  factory WhitelistConfigModel.fromMap(Map<String, dynamic> map) {
    final mode = WhitelistMode.fromName(map['mode']?.toString());
    final version = (map['version'] as num?)?.toInt() ??
        (map['whitelist_version'] as num?)?.toInt() ??
        1;
    final entries = (map['entries'] as List<dynamic>? ?? const [])
        .map((item) {
          if (item is! Map) return null;
          return WhitelistEntryModel.fromMap(Map<String, dynamic>.from(item));
        })
        .whereType<WhitelistEntryModel>()
        .where((entry) => entry.address.isNotEmpty)
        .toList();
    return WhitelistConfigModel(mode: mode, entries: entries, version: version);
  }

  factory WhitelistConfigModel.fromJson(Map<String, dynamic> json) =>
      WhitelistConfigModel.fromMap(json);

  @override
  List<Object?> get props => [mode, entries, version];
}
