import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/repositories/sms_by_date_repository.dart';
import 'bloc/sms_bloc.dart';
import 'views/calendar_card_view.dart';
import 'views/message_list_view.dart';

/// Màn hình SMS theo ngày (MOBILE_FEATURES 6.1–6.4):
/// - Chọn ngày trên calendar (6.1);
/// - SMS/OTP gộp của TẤT CẢ kênh đang tham gia, mỗi dòng ghi rõ kênh nguồn (6.2);
/// - Thông báo tin nhắn SMS mới (FCM chuông) mở thẳng màn này (6.3);
/// - Tự làm mới ngầm khi có tin mới / app quay lại foreground (1.3);
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

class _SmsView extends StatefulWidget {
  const _SmsView();

  @override
  State<_SmsView> createState() => _SmsViewState();
}

class _SmsViewState extends State<_SmsView> {
  /// Tin đến khi app ở nền được isolate nền hiện thông báo, nhưng màn này
  /// không biết → làm mới ngầm mỗi lần app quay lại foreground (1.3).
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => context.read<SmsBloc>().add(const SmsAppResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.smsPageTitle),
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
