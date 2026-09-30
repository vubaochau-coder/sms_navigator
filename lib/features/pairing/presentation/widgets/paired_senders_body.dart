import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../bloc/paired_senders_bloc.dart';
import '../bloc/paired_senders_event.dart';
import '../bloc/paired_senders_state.dart';
import '../pages/qr_scan_page.dart';
import 'paired_sender_card.dart';

/// Widget thân danh sách thiết bị gửi OTP (Dành cho máy nhận).
class PairedSendersBody extends StatelessWidget {
  const PairedSendersBody({
    super.key,
    required this.showAppBar,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Padding(
        padding: Dimens.screenPadding,
        child: BlocBuilder<PairedSendersBloc, PairedSendersState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const ShimmerLoadingList();
            }

            if (state.errorMessage != null) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: 'Có lỗi xảy ra',
                message: state.errorMessage,
                actionLabel: 'Thử lại',
                onAction: () => BlocProvider.of<PairedSendersBloc>(context)
                    .add(const PairedSendersLoadEvent()),
              );
            }

            if (state.devices.isEmpty) {
              return EmptyStateView(
                icon: Icons.phonelink_ring_rounded,
                title: 'Chưa kết nối máy gửi nào',
                message:
                    'Thiết bị này chưa nhận OTP từ máy gửi nào. Vui lòng quét mã QR từ máy gửi để hoàn tất ghép đôi.',
                actionLabel: 'Quét mã QR ghép đôi',
                onAction: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QrScanPage()),
                  );
                  if (context.mounted) {
                    BlocProvider.of<PairedSendersBloc>(context).add(
                      const PairedSendersLoadEvent(),
                    );
                  }
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () {
                final completer = Completer<void>();
                BlocProvider.of<PairedSendersBloc>(context).add(
                  PairedSendersLoadEvent(completer: completer),
                );
                return completer.future;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.devices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = state.devices[index];
                  return PairedSenderCard(item: item);
                },
              ),
            );
          },
        ),
      ),
    );

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết bị gửi OTP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Quét QR ghép đôi mới',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScanPage()),
              );
              if (context.mounted) {
                BlocProvider.of<PairedSendersBloc>(context).add(
                  const PairedSendersLoadEvent(),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () {
              BlocProvider.of<PairedSendersBloc>(context).add(
                const PairedSendersLoadEvent(),
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
