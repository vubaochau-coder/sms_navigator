import 'package:equatable/equatable.dart';

/// Trạng thái server-truth của một kênh Owner gửi xuống native relay.
class RelayChannelSnapshot extends Equatable {
  final String channelId;
  final String channelName;
  final int keyEpoch;
  final String channelKeyBase64;

  const RelayChannelSnapshot({
    required this.channelId,
    required this.channelName,
    required this.keyEpoch,
    required this.channelKeyBase64,
  });

  Map<String, dynamic> toMap() => {
    'channelId': channelId,
    'channelName': channelName,
    'keyEpoch': keyEpoch,
    'channelKeyBase64': channelKeyBase64,
  };

  @override
  List<Object?> get props => [channelId, channelName, keyEpoch, channelKeyBase64];
}

/// Cầu nối tới native relay đa kênh (RelayChannelStore phía Android).
///
/// Tách khỏi [NativeRelayService] để các phần chỉ cần whitelist / battery /
/// logs không phải phụ thuộc vào API quản lý khóa.
///
/// Luồng xoay khóa (approve/revoke):
/// `stageKey` (trước khi gọi server) → server commit → `promoteKey`;
/// server từ chối dứt khoát → `discardKey`; mất mạng / timeout → giữ nguyên
/// để worker tự phục hồi khi gặp 409 EPOCH_OUTDATED và reconcile lần sau.
abstract class RelayChannelBridge {
  Future<void> setCredentials({required String deviceToken, String? apiBaseUrl});

  /// Ghi đè toàn bộ danh sách kênh relay. Kênh không có trong [channels] bị
  /// xóa, trừ các kênh trong [retainChannelIds] (giữ nguyên trạng thái native).
  Future<int> replaceRelayChannels(
    List<RelayChannelSnapshot> channels, {
    List<String> retainChannelIds = const [],
  });

  Future<void> stageKey({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    String? channelName,
  });

  Future<bool> promoteKey({required String channelId, required int keyEpoch});

  Future<void> discardKey({required String channelId, required int keyEpoch});

  /// Gửi lại các SMS bị "park" vì thiếu khóa. Trả về số tin đã enqueue.
  Future<int> flushParkedMessages();
}
