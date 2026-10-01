import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/presentation/widgets/whitelist_blocked_banner.dart';
import '../../data/repositories/otp_list_repository.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../widgets/otp_calendar_card.dart';
import '../widgets/otp_compact_header.dart';
import '../widgets/otp_content_section.dart';
import '../widgets/otp_direction_filter_bar.dart';
import '../widgets/otp_filter_bar.dart';

/// Màn hình xem danh sách OTP theo ngày — Thuần Stateless với BLoC.
class OtpListPage extends StatelessWidget {
  const OtpListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => OtpListBloc(
        repository: ctx.read<OtpListRepository>(),
      )..add(const OtpListLoadEvent()),
      child: const _OtpListView(),
    );
  }
}

class _OtpListView extends StatelessWidget {
  const _OtpListView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            OtpCompactHeader(),
            WhitelistBlockedBanner(),
            OtpCalendarCard(),
            OtpFilterBar(),
            OtpDirectionFilterBar(),
            Expanded(
              child: OtpContentSection(),
            ),
          ],
        ),
      ),
    );
  }
}
