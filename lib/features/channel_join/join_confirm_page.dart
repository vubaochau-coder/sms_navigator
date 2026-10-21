import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/models/invite_preview_model.dart';
import '../../core/models/pairing_session_model.dart';
import '../../core/repositories/join_channel_repository.dart';
import '../../core/repositories/qr_repository.dart';
import '../../core/utils/toast_utils.dart';
import '../../l10n/app_localizations.dart';
import '../device/bloc/device_profile_cubit.dart';
import 'bloc/join_bloc.dart';
import '../../core/l10n/app_l10n.dart';

export 'bloc/join_bloc.dart';

/// Màn hình xác nhận tham gia kênh độc lập sau khi quét QR invite v4:
/// 1. Mount -> Tự động gọi resolve preview metadata (tên kênh, chủ kênh);
/// 2. Hiển thị thông tin kênh và tên thiết bị hiện tại (Read-only, không rename);
/// 3. Bấm [Gửi yêu cầu kết nối] -> claim QR;
/// 4. Thành công hoặc đã có pending request -> Toast & pop về Tab Kênh.
class JoinConfirmPage extends StatelessWidget {
  /// Invite v4 (giai đoạn chuyển tiếp — gỡ ở roadmap GĐ6).
  const JoinConfirmPage({super.key, required String this.inviteRaw})
    : code = null,
      preview = null;

  /// Universal Opaque QR (v3.3): preview đã resolve sẵn, claim bằng [code].
  const JoinConfirmPage.fromQr({
    super.key,
    required String this.code,
    required InvitePreviewModel this.preview,
  }) : inviteRaw = null;

  final String? inviteRaw;
  final String? code;
  final InvitePreviewModel? preview;

  @override
  Widget build(BuildContext context) {
    final currentDeviceName = context.watch<DeviceProfileCubit>().state.deviceName;
    final initialName = currentDeviceName.isNotEmpty
        ? currentDeviceName
        : context.l10n.splashDefaultDeviceName;

    return BlocProvider(
      create: (context) => JoinBloc(
        repository: context.read<JoinChannelRepository>(),
        initialDeviceName: initialName,
        qrRepository: code != null ? context.read<QrRepository>() : null,
      ),
      child: JoinConfirmView(inviteRaw: inviteRaw, code: code, preview: preview),
    );
  }
}

class JoinConfirmView extends StatefulWidget {
  const JoinConfirmView({super.key, this.inviteRaw, this.code, this.preview});

  final String? inviteRaw;
  final String? code;
  final InvitePreviewModel? preview;

  @override
  State<JoinConfirmView> createState() => _JoinConfirmViewState();
}

class _JoinConfirmViewState extends State<JoinConfirmView> {
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _initInvite();
  }

  void _initInvite() {
    final code = widget.code;
    final preview = widget.preview;
    if (code != null && preview != null) {
      // Universal Opaque QR: preview đã có, vào thẳng ready.
      context.read<JoinBloc>().add(JoinInitializedWithPreview(preview: preview, code: code));
      return;
    }
    final invite = InvitePayload.tryParse(widget.inviteRaw ?? '');
    if (invite == null) {
      _parseError = AppL10n.current.joinInvalidQrFormat;
      return;
    }
    if (invite.isExpired) {
      _parseError = AppL10n.current.joinErrorExpired;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JoinBloc>().add(JoinResolveStarted(invite));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinPageTitle),
      ),
      body: BlocConsumer<JoinBloc, JoinState>(
        listener: (context, state) {
          if (state.phase == JoinPhase.resolveFailed && state.isAlreadyPending) {
            ToastUtils.showInfo(
              state.errorMessage ?? context.l10n.joinErrorAlreadyPending,
            );
            Navigator.of(context).pop();
            return;
          }

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
        builder: (context, state) {
          if (_parseError != null) {
            return _buildErrorView(context, _parseError!);
          }

          return switch (state.phase) {
            JoinPhase.resolving => _buildSkeletonView(context),
            JoinPhase.resolveFailed => _buildErrorView(
                context,
                state.errorMessage ?? context.l10n.joinResolveFailedShort,
              ),
            _ => _buildReadyView(context, state, theme, l10n),
          };
        },
      ),
    );
  }

  Widget _buildSkeletonView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            period: const Duration(milliseconds: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 140,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              context.l10n.joinLoadingChannelInfo,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyView(
    BuildContext context,
    JoinState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
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
