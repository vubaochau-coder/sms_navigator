import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../data/models/paired_device_item.dart';
import '../../data/services/pair_management_service.dart';
import '../bloc/paired_devices_cubit.dart';
import '../widgets/paired_receiver_card.dart';
import 'pairing_sender_page.dart';

/// Màn hình quản lý danh sách thiết bị nhận dành cho Máy Gửi (Sender) — Thuần Stateless với BLoC.
class PairedReceiversPage extends StatelessWidget {
  const PairedReceiversPage({
    super.key,
    this.pairManagementService,
  });

  final PairManagementService? pairManagementService;

  @override
  Widget build(BuildContext context) {
    final service = pairManagementService ??
        DependencyContainer.instance.pairManagementService;

    return BlocProvider(
      create: (_) => PairedDevicesCubit(service)..loadReceivers(),
      child: const _PairedReceiversBody(),
    );
  }
}

class _PairedReceiversBody extends StatelessWidget {
  const _PairedReceiversBody();

  Future<void> _toggleActive(
    BuildContext context,
    PairedDeviceItem item,
    bool newValue,
  ) async {
    final cubit = context.read<PairedDevicesCubit>();
    final success = await cubit.toggleActive(item.pairId, newValue);
    if (!context.mounted) return;

    if (success) {
      UiUtils.showSuccessToast(
        context,
        newValue
            ? 'Đã bật chuyển tiếp tới ${item.displayName}'
            : 'Đã tạm dừng chuyển tiếp tới ${item.displayName}',
      );
    } else {
      UiUtils.showErrorToast(
        context,
        'Không thể cập nhật trạng thái. Vui lòng thử lại!',
      );
    }
  }

  Future<void> _confirmRevokePair(
    BuildContext context,
    PairedDeviceItem item,
  ) async {
    final confirmed = await UiUtils.showConfirmDialog(
      context,
      title: 'Hủy kết nối thiết bị?',
      message:
          'Bạn có chắc chắn muốn ngắt kết nối với "${item.displayName}"? Thiết bị này sẽ không thể nhận OTP từ bạn nữa.',
      confirmText: 'Ngắt kết nối',
      isDestructive: true,
      icon: Icons.link_off_rounded,
    );

    if (!confirmed || !context.mounted) return;

    final cubit = context.read<PairedDevicesCubit>();
    final success = await cubit.revokePair(item.pairId);
    if (!context.mounted) return;

    if (success) {
      UiUtils.showSuccessToast(context, 'Đã hủy kết nối thành công');
    } else {
      UiUtils.showErrorToast(context, 'Không thể hủy kết nối. Vui lòng thử lại!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết bị nhận OTP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Ghép nối thêm thiết bị',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PairingSenderPage()),
              );
              if (context.mounted) {
                context.read<PairedDevicesCubit>().loadReceivers();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () {
              context.read<PairedDevicesCubit>().loadReceivers();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: Dimens.screenPadding,
          child: BlocBuilder<PairedDevicesCubit, PairedDevicesState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.errorMessage != null) {
                return EmptyStateView(
                  icon: Icons.cloud_off_rounded,
                  title: 'Có lỗi xảy ra',
                  message: state.errorMessage,
                  actionLabel: 'Thử lại',
                  onAction: () =>
                      context.read<PairedDevicesCubit>().loadReceivers(),
                );
              }

              if (state.devices.isEmpty) {
                return EmptyStateView(
                  icon: Icons.phonelink_erase_rounded,
                  title: 'Chưa có thiết bị nhận nào',
                  message:
                      'Hiện tại chưa có máy nhận nào ghép đôi với thiết bị này. Bấm nút bên dưới để tạo mã QR kết nối.',
                  actionLabel: 'Tạo mã QR ghép đôi',
                  onAction: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PairingSenderPage()),
                    );
                    if (context.mounted) {
                      context.read<PairedDevicesCubit>().loadReceivers();
                    }
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<PairedDevicesCubit>().loadReceivers(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = state.devices[index];
                    return PairedReceiverCard(
                      item: item,
                      isToggling: state.togglingPairIds.contains(item.pairId),
                      onToggleActive: (val) => _toggleActive(context, item, val),
                      onRevokePair: () => _confirmRevokePair(context, item),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
