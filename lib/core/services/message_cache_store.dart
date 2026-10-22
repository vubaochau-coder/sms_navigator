import 'dart:convert';

import '../models/channel_message_model.dart';
import '../utils/app_logger.dart';
import 'local_storage_service.dart';

/// Bản lưu offline của một ngày tin nhắn (BACKLOG 1.7).
class CachedMessageDay {
  const CachedMessageDay({required this.messages, required this.truncated, required this.savedAt});

  /// Vẫn là **ciphertext** — giải mã lại bằng channel key mỗi lần đọc.
  final List<ChannelMessageModel> messages;
  final bool truncated;
  final DateTime savedAt;
}

/// Cache offline tin nhắn theo ngày (BACKLOG 1.7): chỉ lưu đúng payload đã mã
/// hoá đầu-cuối mà server trả về (E2EE at rest — không có plaintext trên
/// đĩa), giữ [maxDays] ngày được xem gần nhất.
class MessageCacheStore {
  MessageCacheStore(this._storage, {this.maxDays = 14, DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const String _prefix = 'sms_cache_v1_';
  static const String _indexKey = 'sms_cache_v1_index';

  final LocalStorageService _storage;
  final int maxDays;
  final DateTime Function() _now;

  Future<void> save(String dayKey, List<ChannelMessageModel> messages, {required bool truncated}) async {
    try {
      final payload = jsonEncode({
        'saved_at': _now().toUtc().toIso8601String(),
        'truncated': truncated,
        'messages': [for (final message in messages) message.toCipherMap()],
      });
      await _storage.setString('$_prefix$dayKey', payload);

      final index = [dayKey, ..._index().where((key) => key != dayKey)];
      for (final evicted in index.skip(maxDays)) {
        await _storage.remove('$_prefix$evicted');
      }
      await _storage.setString(_indexKey, jsonEncode(index.take(maxDays).toList()));
    } catch (e) {
      AppLogger.w('MessageCacheStore', 'Cannot cache $dayKey', e);
    }
  }

  CachedMessageDay? load(String dayKey) {
    final raw = _storage.getString('$_prefix$dayKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse('${map['saved_at']}');
      if (savedAt == null) return null;
      return CachedMessageDay(
        messages: [
          for (final item in (map['messages'] as List? ?? const []))
            ChannelMessageModel.fromMap(Map<String, dynamic>.from(item as Map)),
        ],
        truncated: map['truncated'] == true,
        savedAt: savedAt.toLocal(),
      );
    } catch (e) {
      AppLogger.w('MessageCacheStore', 'Corrupt cache for $dayKey — ignored', e);
      return null;
    }
  }

  List<String> _index() {
    try {
      final raw = _storage.getString(_indexKey);
      return raw == null ? <String>[] : (jsonDecode(raw) as List).map((e) => '$e').toList();
    } catch (_) {
      return <String>[];
    }
  }
}
