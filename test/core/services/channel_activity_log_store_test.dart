import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_event.dart';
import 'package:sms_navigator/core/services/channel_activity_log_store.dart';
import 'package:sms_navigator/core/services/impls/channel_activity_log_store_impl.dart';
import 'package:sms_navigator/core/services/local_storage_service.dart';

class _MemoryStorage implements LocalStorageService {
  final Map<String, Object> data = {};
  int reloads = 0;

  @override
  String? getString(String key) => data[key] as String?;
  @override
  Future<void> setString(String key, String value) async => data[key] = value;
  @override
  bool? getBool(String key) => data[key] as bool?;
  @override
  Future<void> setBool(String key, bool value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
  @override
  Future<void> reload() async => reloads++;
}

void main() {
  late _MemoryStorage storage;
  late ChannelActivityLogStoreImpl store;

  setUp(() {
    storage = _MemoryStorage();
    store = ChannelActivityLogStoreImpl(storage);
  });

  test('records channel events newest first and reads them back', () async {
    await store.record(
      ChannelEvent.fromData(const {
        'kind': 'JOIN_REQUEST',
        'channel_id': 'c1',
        'channel_name': 'Nhà',
        'requester_device_name': 'Pixel 8',
      }),
      at: DateTime(2026, 10, 22, 9),
    );
    await store.record(
      ChannelEvent.fromData(const {'kind': 'REVOKED', 'channel_name': 'Công ty', 'reason': 'ARCHIVED'}),
      at: DateTime(2026, 10, 22, 10),
    );

    final entries = await store.load();

    expect(entries.map((e) => e.kind), [ChannelEventKind.revoked, ChannelEventKind.joinRequest]);
    expect(entries.first.isArchived, isTrue);
    expect(entries.last.actorName, 'Pixel 8');
    expect(entries.last.channelName, 'Nhà');
    expect(entries.last.at, DateTime(2026, 10, 22, 9));
    expect(storage.reloads, greaterThan(0));
  });

  test('skips new messages, unknown kinds and notification taps', () async {
    await store.record(const ChannelEvent(kind: ChannelEventKind.newMessage));
    await store.record(const ChannelEvent(kind: ChannelEventKind.unknown));
    await store.record(const ChannelEvent(kind: ChannelEventKind.approved, openedFromNotification: true));

    expect(await store.load(), isEmpty);
  });

  test('keeps only the most recent ${ChannelActivityLogStore.capacity} events', () async {
    for (var i = 0; i < ChannelActivityLogStore.capacity + 5; i++) {
      await store.record(ChannelEvent(kind: ChannelEventKind.approved, channelName: 'k$i'));
    }

    final entries = await store.load();
    expect(entries, hasLength(ChannelActivityLogStore.capacity));
    expect(entries.first.channelName, 'k${ChannelActivityLogStore.capacity + 4}');
  });

  test('corrupt storage reads as empty', () async {
    storage.data['channel_activity_log'] = 'not json';
    expect(await store.load(), isEmpty);
  });
}
