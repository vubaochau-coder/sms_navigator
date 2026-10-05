import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/toast_utils.dart';
import '../bloc/channel_detail_bloc.dart';

/// BottomSheet hiển thị mã QR mời tham gia kênh kèm bộ đếm ngược 10 phút.
class InviteBottomSheet extends StatefulWidget {
  const InviteBottomSheet({super.key});

  /// Mở BottomSheet hiển thị mã mời (tự động tạo session nếu chưa có hoặc hết hạn).
  static void show(BuildContext context) {
    final bloc = BlocProvider.of<ChannelDetailBloc>(context);
    final session = bloc.state.activeSession;
    if (session == null || session.isExpired) {
      bloc.add(ChannelDetailSessionCreated(bloc.state.channelId));
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
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
    final bloc = BlocProvider.of<ChannelDetailBloc>(context);
    final expiresAt = bloc.state.activeSession?.expiresAt;
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
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<ChannelDetailBloc, ChannelDetailState>(
      listenWhen: (prev, curr) =>
          prev.activeSession?.sessionId != curr.activeSession?.sessionId,
      listener: (context, state) {
        _startCountdown();
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final session = state.activeSession;
        final isMutating = state.isMutating;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.channelDetailInviteSheetTitle,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              if (session != null && !session.isExpired && _remaining > Duration.zero)
                Text(
                  l10n.channelDetailInviteQrExpiresIn(_countdownText),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (session != null && (session.isExpired || _remaining <= Duration.zero))
                Text(
                  l10n.channelDetailInviteQrExpired,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                )
              else
                Text(
                  l10n.channelDetailInviteCreatingQr,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 20),
              if (isMutating && session == null)
                const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (session != null) ...[
                Container(
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
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.channelDetailInviteHint,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isMutating
                            ? null
                            : () => BlocProvider.of<ChannelDetailBloc>(context)
                                .add(
                                  ChannelDetailSessionCreated(state.channelId),
                                ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.channelDetailInviteRegenerate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => ToastUtils.copyToClipboard(
                          session.inviteUrl,
                          context: context,
                          successMessage: l10n.channelDetailInviteCopySuccess,
                        ),
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(l10n.channelDetailInviteCopyLink),
                      ),
                    ),
                  ],
                ),
              ] else
                FilledButton.icon(
                  onPressed: isMutating
                      ? null
                      : () => BlocProvider.of<ChannelDetailBloc>(context).add(
                            ChannelDetailSessionCreated(state.channelId),
                          ),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: Text(l10n.channelDetailInviteCreateAction),
                ),
            ],
          ),
        );
      },
    );
  }
}
