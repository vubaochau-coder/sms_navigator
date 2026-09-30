import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../data/models/paired_device_item.dart';
import '../../data/services/pair_management_service.dart';
import '../bloc/paired_devices_cubit.dart';
import '../widgets/paired_sender_card.dart';
import 'qr_scan_page.dart';

/// Màn hình xem danh sách thiết bị gửi dành cho Máy Nhận (Receiver) — Thuần Stateless với BLoC.
class PairedSendersPage extends StatelessWidget {
  const PairedSendersPage({
    super.key,
    this.pairManagementService,
    this.showAppBar = true,
  });

  final PairManagementService? pairManagementService;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final service =
        pairManagementService ??
        DependencyContainer.instance.pairManagementService;

    return BlocProvider(
      create: (_) => PairedDevicesCubit(service)..loadSenders(),
      child: _PairedSendersBody(showAppBar: showAppBar),
    );
  }
}

class _PairedSendersBody extends StatelessWidget {
  const _PairedSendersBody({required this.showAppBar});

  final bool showAppBar;

  Future<void> _confirmRevokePair(
    BuildContext context,
    PairedDeviceItem item,
  ) async {
    final confirmed = await UiUtils.showConfirmDialog(
      context,
      title: 'Hủy kết nối máy gửi?',
      message:
          'Bạn có chắc chắn muốn ngắt kết nối với "${item.displayName}"? Bạn sẽ không nhận được OTP từ thiết bị này nữa.',
      confirmText: 'Ngắt kết nối',
      isDestructive: true,
      icon: Icons.link_off_rounded,
    );

    if (confirmed && context.mounted) {
      context.read<PairedDevicesCubit>().revokePair(item.pairId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Padding(
        padding: Dimens.screenPadding,
        child: BlocBuilder<PairedDevicesCubit, PairedDevicesState>(
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
                onAction: () =>
                    context.read<PairedDevicesCubit>().loadSenders(),
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
                    context.read<PairedDevicesCubit>().loadSenders();
                  }
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<PairedDevicesCubit>().loadSenders(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.devices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = state.devices[index];
                  return PairedSenderCard(
                    item: item,
                    onRevokePair: () => _confirmRevokePair(context, item),
                  );
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
                context.read<PairedDevicesCubit>().loadSenders();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () {
              context.read<PairedDevicesCubit>().loadSenders();
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
