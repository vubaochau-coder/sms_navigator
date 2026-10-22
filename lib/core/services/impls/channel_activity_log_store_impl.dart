import 'dart:convert';

import '../../constants/storage_keys.dart';
import '../../models/channel_activity_entry.dart';
import '../../models/channel_event.dart';
import '../channel_activity_log_store.dart';
import '../local_storage_service.dart';

class ChannelActivityLogStoreImpl implements ChannelActivityLogStore {
  ChannelActivityLogStoreImpl(this._storage);

  final LocalStorageService _storage;

  static const Set<ChannelEventKind> _recordedKinds = {
    ChannelEventKind.joinRequest,
    ChannelEventKind.approved,
    ChannelEventKind.revoked,
    ChannelEventKind.memberLeft,
  };

  @override
  Future<void> record(ChannelEvent event, {DateTime? at}) async {
    if (event.openedFromNotification || !_recordedKinds.contains(event.kind)) return;
    await _storage.reload();
    final entries = [
      ChannelActivityEntry.fromEvent(event, at ?? DateTime.now()),
      ..._read(),
    ].take(ChannelActivityLogStore.capacity);
    await _storage.setString(
      StorageKeys.channelActivityLog,
      jsonEncode(entries.map((entry) => entry.toMap()).toList()),
    );
  }

  @override
  Future<List<ChannelActivityEntry>> load() async {
    await _storage.reload();
    return _read();
  }

  List<ChannelActivityEntry> _read() {
    final raw = _storage.getString(StorageKeys.channelActivityLog);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((item) => ChannelActivityEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
