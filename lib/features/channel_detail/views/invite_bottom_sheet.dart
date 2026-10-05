import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/repositories/channel_repository.dart';
import '../../../core/utils/bottom_sheet_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../bloc/channel_detail_bloc.dart';

/// BottomSheet hiển thị mã QR mời tham gia kênh kèm bộ đếm ngược 10 phút.
/// Phong cách thiết kế đồng bộ chuẩn dự án theo [BottomSheetUtils.showBaseForm].
class InviteBottomSheet extends StatefulWidget {
  const InviteBottomSheet({super.key});

  /// Mở BottomSheet hiển thị mã mời với ChannelInviteBloc độc lập.
  static void show(BuildContext context, {String? channelId}) {
    final effectiveChannelId =
        channelId ?? context.read<ChannelDetailBloc>().state.channelId;
    final repository = context.read<ChannelRepository>();

    BottomSheetUtils.showBaseForm(
      context: context,
      child: BlocProvider(
        create: (_) => ChannelInviteBloc(
          repository: repository,
          channelId: effectiveChannelId,
        )..add(const ChannelInviteStarted()),
        child: const InviteBottomSheet(),
      ),
    );
  }

  @override
  State<InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends State<InviteBottomSheet> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _ticker?.cancel();
    final bloc = BlocProvider.of<ChannelInviteBloc>(context);
    final expiresAt = bloc.state.session?.expiresAt;
    final deadline = DateTime.tryParse(expiresAt ?? '');
    if (deadline == null) {
      _remaining = Duration.zero;
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = deadline.difference(DateTime.now());
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining = left.isNegative ? Duration.zero : left;
      });
      if (left <= Duration.zero) {
        timer.cancel();
      }
    });
    final initial = deadline.difference(DateTime.now());
    _remaining = initial.isNegative ? Duration.zero : initial;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _countdownText {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return BlocConsumer<ChannelInviteBloc, ChannelInviteState>(
      listenWhen: (prev, curr) =>
          prev.session?.sessionId != curr.session?.sessionId,
      listener: (context, state) {
        _startCountdown();
      },
      builder: (context, state) {
        final session = state.session;
        final isLoading = state.isLoading;
        final hasActiveSession =
            session != null && !session.isExpired && _remaining > Duration.zero;
        final isExpiredSession =
            session != null && (session.isExpired || _remaining <= Duration.zero);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề: Icon trong circle container + Tên BottomSheet
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.channelDetailInviteSheetTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Hàng meta: Đếm ngược thời gian hết hạn hoặc trạng thái tạo mã
              Row(
                children: [
                  Icon(
                    hasActiveSession
                        ? Icons.access_time_rounded
                        : (isExpiredSession
                            ? Icons.error_outline_rounded
                            : Icons.hourglass_empty_rounded),
                    size: 14,
                    color: hasActiveSession
                        ? colorScheme.primary
                        : (isExpiredSession
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasActiveSession
                        ? l10n.channelDetailInviteQrExpiresIn(_countdownText)
                        : (isExpiredSession
                            ? l10n.channelDetailInviteQrExpired
                            : l10n.channelDetailInviteCreatingQr),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          hasActiveSession ? FontWeight.w600 : FontWeight.normal,
                      color: hasActiveSession
                          ? colorScheme.primary
                          : (isExpiredSession
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nội dung chính: Loading / QR Code + Hộp hint bảo mật
              if (isLoading && session == null)
                const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (session != null) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: session.inviteUrl,
                      size: 190,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    l10n.channelDetailInviteHint,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],

              // Khoảng cách rộng giữa nội dung và nút bấm giống sms_detail
              const SizedBox(height: 24),

              // Hàng nút bấm hành động (Full width, height 48, bo góc 12)
              if (session != null)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () =>
                                  BlocProvider.of<ChannelInviteBloc>(context)
                                      .add(const ChannelInviteRegenerated()),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            l10n.channelDetailInviteRegenerate,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () => ToastUtils.copyToClipboard(
                            session.inviteUrl,
                            context: context,
                            successMessage:
                                l10n.channelDetailInviteCopySuccess,
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(
                            l10n.channelDetailInviteCopyLink,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => BlocProvider.of<ChannelInviteBloc>(context)
                            .add(const ChannelInviteRegenerated()),
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: Text(
                      l10n.channelDetailInviteCreateAction,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
