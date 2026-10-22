import 'dart:async';

import '../../models/activity_item.dart';
import '../../models/channel_activity_entry.dart';
import '../../models/channel_event.dart';
import '../../models/relay_log_entry.dart';
import '../../services/channel_activity_log_store.dart';
import '../../services/native_relay_service.dart';
import '../../utils/app_logger.dart';
import '../activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  /// Ghi mọi sự kiện kênh đến khi app đang mở (isolate nền tự ghi phần của nó).
  ActivityRepositoryImpl({
    required NativeRelayService nativeRelayService,
    required ChannelActivityLogStore logStore,
    Stream<ChannelEvent> channelEvents = const Stream.empty(),
  })  : _nativeRelayService = nativeRelayService,
        _logStore = logStore {
    _subscription = channelEvents.listen(_onChannelEvent);
  }

  final NativeRelayService _nativeRelayService;
  final ChannelActivityLogStore _logStore;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  StreamSubscription<ChannelEvent>? _subscription;

  @override
  Stream<void> get changes => _changes.stream;

  Future<void> _onChannelEvent(ChannelEvent event) async {
    try {
      await _logStore.record(event);
    } catch (e) {
      AppLogger.w('ActivityRepository', 'Cannot record channel event', e);
    }
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  Future<List<ActivityItem>> loadActivity() async {
    // Hai nguồn độc lập, tải song song; nguồn nào lỗi thì coi như rỗng.
    final relayFuture = _nativeRelayService
        .getRecentLogs()
        .catchError((Object _) => <Map<String, dynamic>>[]);
    final channelFuture = _logStore
        .load()
        .catchError((Object _) => <ChannelActivityEntry>[]);
    final relayLogs = await relayFuture;
    final channelLogs = await channelFuture;
    final items = <ActivityItem>[
      for (final log in relayLogs) RelayActivityItem(RelayLogEntry.fromMap(log)),
      for (final entry in channelLogs) ChannelActivityItem(entry),
    ];
    items.sort((a, b) {
      final aAt = a.at, bAt = b.at;
      if (aAt == null) return bAt == null ? 0 : 1;
      if (bAt == null) return -1;
      return bAt.compareTo(aAt);
    });
    return items;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _changes.close();
  }
}
