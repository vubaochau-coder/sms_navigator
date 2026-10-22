import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_event.dart';

void main() {
  test('parses a NEW_MESSAGE data payload', () {
    final event = ChannelEvent.fromData(const {
      'type': 'CHANNEL_EVENT',
      'kind': 'NEW_MESSAGE',
      'channel_id': 'ch-1',
      'channel_name': 'Kênh nhà',
      'sequence_number': '42',
      'sender_device_id': 'owner-1',
    });

    expect(event.kind, ChannelEventKind.newMessage);
    expect(event.channelId, 'ch-1');
    expect(event.channelName, 'Kênh nhà');
    expect(event.sequenceNumber, 42);
    expect(event.senderDeviceId, 'owner-1');
    expect(event.affectsMessages, isTrue);
  });

  test('unknown / missing fields stay null', () {
    final event = ChannelEvent.fromData(const {'kind': 'SOMETHING', 'channel_id': ' '});
    expect(event.kind, ChannelEventKind.unknown);
    expect(event.channelId, isNull);
    expect(event.sequenceNumber, isNull);
    expect(event.affectsMessages, isFalse);
  });

  test('approved / revoked affect the message list, join requests do not', () {
    expect(const ChannelEvent(kind: ChannelEventKind.approved).affectsMessages, isTrue);
    expect(const ChannelEvent(kind: ChannelEventKind.revoked).affectsMessages, isTrue);
    expect(const ChannelEvent(kind: ChannelEventKind.joinRequest).affectsMessages, isFalse);
  });
}
