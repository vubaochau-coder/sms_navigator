import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Nội dung (đã giải mã) của một bản sao lưu `.smsnav` (BACKLOG 1.1).
///
/// Chứa đủ để một bản cài mới **trở thành đúng thiết bị cũ**: cùng
/// `device_id` + `device_token` (server nhận ra), cùng identity X25519 (mở
/// được envelope), cùng channel key mọi epoch (đọc được tin cũ, Owner relay
/// tiếp được ngay).
class BackupPayload extends Equatable {
  const BackupPayload({
    required this.deviceId,
    required this.deviceToken,
    required this.identityPrivateKey,
    required this.identityPublicKey,
    required this.createdAt,
    this.deviceName,
    this.serverUrl,
    this.channelKeys = const {},
  });

  static const int schemaVersion = 1;

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    final device = DataConverter.cvToMap<String, dynamic>(json['device']) ?? const {};
    final identity = DataConverter.cvToMap<String, dynamic>(json['identity']) ?? const {};
    final rawChannels = DataConverter.cvToMap<String, dynamic>(json['channels']) ?? const {};

    final channels = <String, Map<int, String>>{};
    rawChannels.forEach((channelId, rawEpochs) {
      final epochs = DataConverter.cvToMap<String, dynamic>(rawEpochs) ?? const {};
      final keys = <int, String>{};
      epochs.forEach((epoch, key) {
        final parsedEpoch = int.tryParse(epoch);
        final parsedKey = DataConverter.cvToString(key);
        if (parsedEpoch != null && parsedKey != null && parsedKey.isNotEmpty) {
          keys[parsedEpoch] = parsedKey;
        }
      });
      if (channelId.isNotEmpty && keys.isNotEmpty) channels[channelId] = keys;
    });

    return BackupPayload(
      deviceId: DataConverter.cvToString(device['id'], '')!,
      deviceName: DataConverter.cvToString(device['name']),
      deviceToken: DataConverter.cvToString(device['token'], '')!,
      serverUrl: DataConverter.cvToString(device['server_url']),
      identityPrivateKey: DataConverter.cvToString(identity['private_key'], '')!,
      identityPublicKey: DataConverter.cvToString(identity['public_key'], '')!,
      channelKeys: channels,
      createdAt: DataConverter.cvToDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String deviceId;
  final String? deviceName;
  final String deviceToken;
  final String? serverUrl;
  final String identityPrivateKey;
  final String identityPublicKey;

  /// `channelId → (epoch → channel key Base64)`.
  final Map<String, Map<int, String>> channelKeys;
  final DateTime createdAt;

  /// Đủ dữ liệu để khôi phục danh tính hay không.
  bool get isComplete =>
      deviceId.isNotEmpty &&
      deviceToken.isNotEmpty &&
      identityPrivateKey.isNotEmpty &&
      identityPublicKey.isNotEmpty;

  int get channelCount => channelKeys.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schema': schemaVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
    'device': <String, dynamic>{
      'id': deviceId,
      'name': ?deviceName,
      'token': deviceToken,
      'server_url': ?serverUrl,
    },
    'identity': <String, dynamic>{
      'private_key': identityPrivateKey,
      'public_key': identityPublicKey,
    },
    'channels': <String, dynamic>{
      for (final entry in channelKeys.entries)
        entry.key: <String, String>{
          for (final key in entry.value.entries) key.key.toString(): key.value,
        },
    },
  };

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    deviceToken,
    serverUrl,
    identityPrivateKey,
    identityPublicKey,
    channelKeys,
    createdAt,
  ];
}
