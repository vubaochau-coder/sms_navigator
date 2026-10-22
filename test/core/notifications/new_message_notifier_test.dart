import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/constants/storage_keys.dart';
import 'package:sms_navigator/core/services/local_storage_service.dart';
import 'package:sms_navigator/core/models/channel_event.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/core/notifications/local_notification_presenter.dart';
import 'package:sms_navigator/core/notifications/new_message_notifier.dart';
import 'package:sms_navigator/core/notifications/notification_content.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/usecases/resolve_incoming_message_use_case.dart';

class FakePresenter implements LocalNotificationPresenter {
  final List<OtpNotificationContent> otps = [];
  final List<(BellNotificationContent, int?, NotificationPayload?)> bells = [];

  @override
  Future<void> showOtp(OtpNotificationContent content) async => otps.add(content);

  @override
  Future<void> showBell(BellNotificationContent content, {int? id, NotificationPayload? payload}) async =>
      bells.add((content, id, payload));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class FakeResolve implements ResolveIncomingMessageUseCase {
  ChannelMessageModel? result;
  Object? error;
  int calls = 0;

  @override
  Future<ChannelMessageModel> call({required String channelId, required int sequenceNumber}) async {
    calls++;
    if (error != null) throw error!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class FakeDeviceStorage implements DeviceStorageService {
  String? deviceId = 'member-1';

  @override
  Future<String?> getDeviceId() async => deviceId;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

const _fallback = BellNotificationContent(title: 'Tin nhắn SMS mới', body: 'generic');

const _event = ChannelEvent(
  kind: ChannelEventKind.newMessage,
  channelId: 'ch-1',
  sequenceNumber: 7,
  senderDeviceId: 'owner-1',
);

ChannelMessageModel _decrypted(String? text, {bool failed = false}) => ChannelMessageModel(
  messageId: '',
  channelId: 'ch-1',
  channelName: 'Kênh nhà',
  sequenceNumber: 7,
  keyEpoch: 2,
  ciphertext: 'c',
  nonce: 'n',
  sender: 'VCB',
  decryptedOtp: text,
  decryptFailed: failed,
);

void main() {
  late FakePresenter presenter;
  late FakeResolve resolve;
  late FakeDeviceStorage storage;
  late NewMessageNotifier notifier;

  setUp(() {
    presenter = FakePresenter();
    resolve = FakeResolve();
    storage = FakeDeviceStorage();
    notifier = NewMessageNotifier(
      resolveIncomingMessage: resolve,
      deviceStorage: storage,
      presenter: presenter,
    );
  });

  test('decrypted message → OTP notification with the code', () async {
    resolve.result = _decrypted('Ma OTP 482913');

    final outcome = await notifier.handle(_event, fallback: _fallback);

    expect(outcome, NewMessageNotifyOutcome.otpShown);
    expect(presenter.otps.single.code, '482913');
    expect(presenter.otps.single.id, notificationIdFor('ch-1', 7));
    expect(presenter.bells, isEmpty);
  });

  test('decrypt failure → generic notification for the same message id', () async {
    resolve.result = _decrypted(null, failed: true);

    final outcome = await notifier.handle(_event, fallback: _fallback);

    expect(outcome, NewMessageNotifyOutcome.fallbackShown);
    expect(presenter.otps, isEmpty);
    final (content, id, payload) = presenter.bells.single;
    expect(content, _fallback);
    expect(id, notificationIdFor('ch-1', 7));
    expect(payload, const NotificationPayload(channelId: 'ch-1', sequenceNumber: 7));
  });

  test('network error → generic notification', () async {
    resolve.error = Exception('offline');
    expect(await notifier.handle(_event, fallback: _fallback), NewMessageNotifyOutcome.fallbackShown);
    expect(presenter.bells, hasLength(1));
  });

  test('old server payload without sequence_number → generic, no fetch', () async {
    const legacy = ChannelEvent(kind: ChannelEventKind.newMessage, channelId: 'ch-1');
    expect(await notifier.handle(legacy, fallback: _fallback), NewMessageNotifyOutcome.fallbackShown);
    expect(resolve.calls, 0);
    expect(presenter.bells.single.$2, isNull);
  });

  test('message relayed by this very device → nothing shown', () async {
    storage.deviceId = 'owner-1';
    expect(await notifier.handle(_event, fallback: _fallback), NewMessageNotifyOutcome.skippedOwnMessage);
    expect(resolve.calls, 0);
    expect(presenter.bells, isEmpty);
    expect(presenter.otps, isEmpty);
  });

  test('with "notify own relayed" switched on, the relaying device gets the OTP too (1.8)', () async {
    storage.deviceId = 'owner-1';
    resolve.result = _decrypted('Ma OTP 482913');
    final prefs = _Prefs()..data[StorageKeys.notifyOwnRelayedMessages] = true;
    final notifyOwn = NewMessageNotifier(
      resolveIncomingMessage: resolve,
      deviceStorage: storage,
      presenter: presenter,
      preferences: prefs,
    );

    expect(await notifyOwn.handle(_event, fallback: _fallback), NewMessageNotifyOutcome.otpShown);
    expect(presenter.otps.single.code, '482913');
  });
}

class _Prefs implements LocalStorageService {
  final Map<String, Object> data = {};

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
}
