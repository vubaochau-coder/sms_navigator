import 'package:flutter/material.dart';

import '../../../core/models/channel_message_model.dart';
import '../sms_detail_page.dart';

export '../sms_detail_page.dart';

/// Lớp tương thích ngược, chuyển tiếp sang [SmsDetailPage].
class SmsDetailBottomSheet {
  const SmsDetailBottomSheet._();

  static void show(BuildContext context, ChannelMessageModel message) {
    SmsDetailPage.navigate(context, message);
  }
}
