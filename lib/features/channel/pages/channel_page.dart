import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/utils/dialog_utils.dart';
import '../bloc/approval_bloc.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/repositories/channel_repository.dart';

/// Chi tiết kênh của bạn (Owner) — MOBILE_FEATURES 2.3 + 4.1–4.4:
/// tên kênh, số thành viên + danh sách thành viên, hàng đợi duyệt (badge),
/// QR invitation deeplink v4 (countdown 10', tạo lại, hint bảo mật).
class ChannelPage extends StatelessWidget {
  const ChannelPage({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApprovalBloc(
        repository: context.read<ChannelRepository>(),
        channelId: channelId,
      )..add(ApprovalLoaded(channelId)),
      child: const _ChannelPageView(),
    );
  }
}

class _ChannelPageView extends StatelessWidget {
  const _ChannelPageView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApprovalBloc, ApprovalState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          DialogUtils.showInfoDialog(
            context: context,
            title: 'Có lỗi xảy ra',
            message: state.errorMessage!,
          );
        }
        if (state.successMessage != null) {
          DialogUtils.showInfoDialog(
            context: context,
            title: 'Thành công',
            message: state.successMessage!,
          );
        }
      },
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(
            title: Text(detail?.name ?? 'Chi tiết kênh'),
            actions: [
              _PendingApprovalBadge(count: state.pendingCount),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<ApprovalBloc>()
                        .add(ApprovalLoaded(state.channelId));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ChannelSummary(state: state),
                      const SizedBox(height: 16),
                      _InviteSection(state: state),
                      const SizedBox(height: 16),
                      if (state.pendingRequests.isNotEmpty) ...[
                        _PendingRequestsSection(requests: state.pendingRequests),
                        const SizedBox(height: 16),
                      ],
                      _MembersSection(state: state),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _PendingApprovalBadge extends StatelessWidget {
  const _PendingApprovalBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.pending_actions_outlined),
      ),
    );
  }
}

class _ChannelSummary extends StatelessWidget {
  const _ChannelSummary({required this.state});

  final ApprovalState state;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dns_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail?.name ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Máy chủ (Owner): ${detail?.ownerDeviceName ?? '—'}'),
            const SizedBox(height: 4),
            Text('${detail?.memberCount ?? 0} thành viên'),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text('Epoch hiện tại: ${detail.currentEpoch}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _InviteSection extends StatefulWidget {
  const _InviteSection({required this.state});

  final ApprovalState state;

  @override
  State<_InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends State<_InviteSection> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant _InviteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeSession?.sessionId !=
        widget.state.activeSession?.sessionId) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _ticker?.cancel();
    final expiresAt = widget.state.activeSession?.expiresAt;
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
    return '${_remaining.inHours}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.state.activeSession;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded),
                const SizedBox(width: 8),
                const Expanded(child: Text('Mời thành viên')),
                if (session != null)
                  Text(
                    'Hết hạn sau $_countdownText',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (session == null)
              Center(
                child: FilledButton.icon(
                  onPressed: widget.state.isMutating
                      ? null
                      : () => context
                          .read<ApprovalBloc>()
                          .add(ApprovalSessionCreated(widget.state.channelId)),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('Tạo mã mời QR'),
                ),
              )
            else ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: session.inviteUrl,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '· QR không chứa mật khẩu hay khóa nào — chỉ chứa mã mời một lần.\n'
                '· Mã dùng trong 10 phút và chỉ dùng được 1 lần.\n'
                '· Nếu xuất QR ra Gallery, hãy xóa ảnh sau khi dùng xong.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.state.isMutating
                        ? null
                        : () => context.read<ApprovalBloc>().add(
                            ApprovalSessionCreated(widget.state.channelId),
                          ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tạo lại mã'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingRequestsSection extends StatelessWidget {
  const _PendingRequestsSection({required this.requests});

  final List<PairingRequestModel> requests;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yêu cầu chờ duyệt (${requests.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final request in requests)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_add_alt_1_rounded),
                title: Text(request.requesterDeviceName),
                subtitle: Text(_formatTime(request.createdAt)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Từ chối',
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _reject(context, request),
                    ),
                    IconButton(
                      tooltip: 'Duyệt',
                      icon: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _approve(context, request),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _approve(BuildContext context, PairingRequestModel request) {
    DialogUtils.showConfirmDialog(
      context: context,
      title: 'Duyệt thành viên?',
      message:
          'Duyệt "${request.requesterDeviceName}" sẽ tự động xoay khóa kênh và cấp khóa mới cho mọi thành viên.',
      confirmText: 'Duyệt',
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        context.read<ApprovalBloc>().add(ApprovalConfirmed(request));
      }
    });
  }

  void _reject(BuildContext context, PairingRequestModel request) {
    DialogUtils.showConfirmDialog(
      context: context,
      title: 'Từ chối yêu cầu?',
      message:
          'Từ chối "${request.requesterDeviceName}"? Mã QR đã dùng cho yêu cầu này sẽ không còn hiệu lực.',
      confirmText: 'Từ chối',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        context.read<ApprovalBloc>().add(ApprovalRejected(request));
      }
    });
  }

  String _formatTime(String iso) {
    final time = DateTime.tryParse(iso);
    if (time == null) return iso;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.state});

  final ApprovalState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thành viên (${state.members.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final member in state.members)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  member.isActive ? Icons.smartphone_rounded : Icons.block,
                  color: member.isActive ? null : Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  member.deviceName,
                  style: TextStyle(
                    decoration: member.isActive
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  member.isActive
                      ? 'Tham gia epoch ${member.joinedEpoch}'
                      : 'Đã thu hồi',
                ),
                trailing: member.isActive
                    ? IconButton(
                        tooltip: 'Thu hồi',
                        icon: Icon(
                          Icons.person_remove_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _revoke(context, member),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  void _revoke(BuildContext context, ChannelMemberModel member) {
    DialogUtils.showConfirmDialog(
      context: context,
      title: 'Thu hồi thành viên?',
      message:
          'Thu hồi "${member.deviceName}" là hành động vĩnh viễn. Khóa kênh sẽ được xoay ngay để member này không đọc được tin mới.',
      confirmText: 'Thu hồi',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        context
            .read<ApprovalBloc>()
            .add(ApprovalMemberRevoked(member.deviceId));
      }
    });
  }
}
