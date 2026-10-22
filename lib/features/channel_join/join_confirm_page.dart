import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/models/invite_preview_model.dart';
import '../../core/repositories/qr_repository.dart';
import '../../core/ui/toast_utils.dart';
import '../device/bloc/device_profile_cubit.dart';
import 'bloc/join_bloc.dart';

export 'bloc/join_bloc.dart';

/// Màn hình xác nhận tham gia kênh sau khi quét Universal Opaque QR (v3.3):
/// 1. Preview (tên kênh, chủ kênh) đã resolve sẵn ở `QrEntryPage`;
/// 2. Hiển thị thông tin kênh và tên thiết bị hiện tại (read-only);
/// 3. Bấm [Gửi yêu cầu kết nối] -> claim bằng [code];
/// 4. Thành công -> Toast & pop về Tab Kênh.
class JoinConfirmPage extends StatelessWidget {
  const JoinConfirmPage.fromQr({
    super.key,
    required this.code,
    required this.preview,
  });

  final String code;
  final InvitePreviewModel preview;

  @override
  Widget build(BuildContext context) {
    // read (không watch): tên chỉ dùng làm giá trị khởi tạo cho JoinBloc.
    final currentDeviceName = context.read<DeviceProfileCubit>().state.deviceName;
    final initialName = currentDeviceName.isNotEmpty
        ? currentDeviceName
        : context.l10n.splashDefaultDeviceName;

    return BlocProvider(
      create: (context) => JoinBloc(
        qrRepository: context.read<QrRepository>(),
        initialDeviceName: initialName,
      )..add(JoinInitializedWithPreview(preview: preview, code: code)),
      child: const JoinConfirmView(),
    );
  }
}

class JoinConfirmView extends StatelessWidget {
  const JoinConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinPageTitle),
      ),
      body: BlocConsumer<JoinBloc, JoinState>(
        listener: (context, state) {
          if (state.phase == JoinPhase.claimSuccess) {
            final name = state.channelName.isNotEmpty ? state.channelName : context.l10n.joinChannelFallbackName;
            ToastUtils.showSuccess(context.l10n.joinRequestSent(name));
            Navigator.of(context).pop();
            return;
          }

          if (state.phase == JoinPhase.claimFailed) {
            ToastUtils.showError(
              state.errorMessage ?? context.l10n.joinClaimFailedRetry,
            );
          }
        },
        builder: (context, state) => JoinReadyView(state: state),
      ),
    );
  }
}

/// Màn đã có thông tin kênh: xem lại và gửi yêu cầu tham gia.
class JoinReadyView extends StatelessWidget {
  const JoinReadyView({super.key, required this.state});

  final JoinState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final channelName = state.channelName.isNotEmpty ? state.channelName : '—';
    final ownerName = state.ownerDeviceName.isNotEmpty ? state.ownerDeviceName : '—';
    final deviceName = state.deviceName.isNotEmpty ? state.deviceName : context.l10n.joinYourDeviceFallback;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Kênh
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hub_rounded,
                        size: 32,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      channelName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.joinOwnerLabel(ownerName),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card Thiết bị gửi yêu cầu (Read-only)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  l10n.joinDeviceNameLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                subtitle: Text(
                  deviceName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Nút bấm xác nhận
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: state.isClaiming
                  ? null
                  : () {
                      context.read<JoinBloc>().add(JoinSubmitted(deviceName));
                    },
              child: state.isClaiming
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      l10n.joinSendRequestAction,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
