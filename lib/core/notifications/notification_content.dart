import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../l10n/app_l10n.dart';
import '../models/channel_message_model.dart';
import '../utils/data_converter.dart';
import '../utils/otp_code_extractor.dart';

/// Nội dung thông báo chung (không có OTP) — dựng từ FCM (§7).
class BellNotificationContent extends Equatable {
  const BellNotificationContent({required this.title, required this.body});

  /// Ưu tiên notification block của server; không có thì tự dựng từ data payload.
  factory BellNotificationContent.fromRemoteMessage(RemoteMessage message) {
    final l10n = AppL10n.current;
    final notification = message.notification;
    if (notification != null) {
      return BellNotificationContent(
        title: notification.title ?? 'SMS Navigator',
        body: notification.body ?? l10n.notificationDefaultBody,
      );
    }

    String? nonEmpty(String key) {
      final value = message.data[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final channelName = nonEmpty('channel_name');
    final requesterName = nonEmpty('requester_device_name');

    return switch (message.data['kind']) {
      'JOIN_REQUEST' => BellNotificationContent(
        title: l10n.notificationJoinRequestTitle,
        body: switch ((requesterName, channelName)) {
          (final String requester, final String channel) =>
            l10n.notificationJoinRequestBody(requester, channel),
          (final String requester, null) => l10n.notificationJoinRequestBodyNoChannel(requester),
          _ => l10n.notificationJoinRequestBodyGeneric,
        },
      ),
      'APPROVED' => BellNotificationContent(
        title: l10n.notificationApprovedTitle,
        body: channelName != null
            ? l10n.notificationApprovedBody(channelName)
            : l10n.notificationApprovedBodyGeneric,
      ),
      'REVOKED' => BellNotificationContent(
        title: l10n.notificationRevokedTitle,
        body: channelName != null
            ? l10n.notificationRevokedBody(channelName)
            : l10n.notificationRevokedBodyGeneric,
      ),
      'NEW_MESSAGE' => BellNotificationContent(
        title: l10n.notificationNewMessageTitle,
        body: channelName != null
            ? l10n.notificationNewMessageBody(channelName)
            : l10n.notificationNewMessageBodyGeneric,
      ),
      _ => BellNotificationContent(title: 'SMS Navigator', body: l10n.notificationDefaultBody),
    };
  }

  final String title;
  final String body;

  @override
  List<Object?> get props => [title, body];
}

/// Payload gắn vào thông báo cục bộ để xử lý khi người dùng chạm / bấm nút.
/// Chỉ nằm trên máy (PendingIntent), không đi qua server.
class NotificationPayload extends Equatable {
  const NotificationPayload({this.channelId, this.sequenceNumber, this.copyText});

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = DataConverter.cvToMap<String, dynamic>(jsonDecode(raw));
      if (map == null) return null;
      return NotificationPayload(
        channelId: DataConverter.cvToString(map['c']),
        sequenceNumber: DataConverter.cvToInt(map['s']),
        copyText: DataConverter.cvToString(map['t']),
      );
    } catch (_) {
      return null;
    }
  }

  final String? channelId;
  final int? sequenceNumber;

  /// Chuỗi được sao chép khi bấm "Sao chép" (mã OTP, hoặc cả tin nếu không tách được mã).
  final String? copyText;

  String encode() => jsonEncode(<String, Object>{
    'c': ?channelId,
    's': ?sequenceNumber,
    't': ?copyText,
  });

  @override
  List<Object?> get props => [channelId, sequenceNumber, copyText];
}

/// Thông báo hiển thị thẳng OTP đã giải mã (MOBILE_FEATURES 1.2).
class OtpNotificationContent extends Equatable {
  const OtpNotificationContent({
    required this.id,
    required this.title,
    required this.body,
    required this.copyText,
    required this.payload,
    this.code,
    this.channelName,
  });

  /// [message] phải là tin đã giải mã thành công (`decryptedOtp != null`).
  factory OtpNotificationContent.fromMessage(ChannelMessageModel message) {
    final l10n = AppL10n.current;
    final text = (message.decryptedOtp ?? '').trim();
    final code = OtpCodeExtractor.extract(text);
    final rawSender = message.sender?.trim();
    final sender = rawSender == null || rawSender.isEmpty ? null : rawSender;

    final title = code != null
        ? l10n.notificationOtpTitle(code)
        : (sender ?? l10n.notificationNewMessageTitle);
    final body = sender != null && code != null ? '$sender: $text' : text;
    final copyText = code ?? text;

    return OtpNotificationContent(
      id: notificationIdFor(message.channelId, message.sequenceNumber),
      title: title,
      body: body,
      code: code,
      copyText: copyText,
      channelName: message.channelName.isEmpty ? null : message.channelName,
      payload: NotificationPayload(
        channelId: message.channelId,
        sequenceNumber: message.sequenceNumber,
        copyText: copyText,
      ),
    );
  }

  final int id;
  final String title;
  final String body;
  final String? code;
  final String copyText;
  final String? channelName;
  final NotificationPayload payload;

  @override
  List<Object?> get props => [id, title, body, code, copyText, channelName, payload];
}

/// Id ổn định cho một tin (FNV-1a 31-bit) — isolate nền và isolate chính
/// cùng ra một id, nên thông báo chung có thể được thay bằng thông báo OTP
/// thay vì hiện trùng.
int notificationIdFor(String channelId, int sequenceNumber) {
  var hash = 0x811c9dc5;
  for (final unit in '$channelId#$sequenceNumber'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
