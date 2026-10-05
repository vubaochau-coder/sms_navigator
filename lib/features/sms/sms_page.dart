import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/repositories/sms_by_date_repository.dart';
import '../device/views/device_profile_button.dart';
import 'bloc/sms_bloc.dart';
import 'views/calendar_card_view.dart';
import 'views/message_list_view.dart';

/// Màn hình SMS theo ngày (MOBILE_FEATURES 6.1–6.4):
/// - Chọn ngày trên calendar (6.1);
/// - SMS/OTP gộp của TẤT CẢ kênh đang tham gia, mỗi dòng ghi rõ kênh nguồn (6.2);
/// - Thông báo SMS/OTP mới (FCM chuông) mở thẳng màn này (6.3);
/// - Trạng thái rỗng hiển thị rõ ràng (6.4).
class SmsPage extends StatelessWidget {
  const SmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return SmsBloc(repository: context.read<SmsByDateRepository>())
          ..add(const SmsLoadDataEvent());
      },
      child: const _SmsView(),
    );
  }
}

class _SmsView extends StatelessWidget {
  const _SmsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.smsPageTitle),
        actions: const [
          DeviceProfileButton(),
        ],
      ),
      body: Column(
        children: const [
          SizedBox(height: 4),
          CalendarCardView(),
          SizedBox(height: 16),
          Expanded(child: MessageListView()),
        ],
      ),
    );
  }
}
