import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/dialog_utils.dart';
import 'bloc/join_bloc.dart';
import '../../core/models/pairing_session_model.dart';
import '../../core/repositories/join_channel_repository.dart';

/// Đích đến của invite QR/deeplink v4 (3.1→3.6):
/// 1. Parse invite → dialog xác nhận (tên kênh + tên máy chủ + tên thiết bị
///    sửa được) — KHÔNG gọi API (3.2);
/// 2. Bấm [Gửi yêu cầu kết nối] mới claim (3.3);
/// 3. Màn "Đang chờ duyệt" + animation (3.4), hủy được (3.5);
/// 4. Mã lỗi rõ ràng + hướng dẫn xin mã mới (3.6).
class JoinConfirmPage extends StatelessWidget {
  const JoinConfirmPage({super.key, required this.inviteRaw});

  final String inviteRaw;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JoinBloc(
        repository: context.read<JoinChannelRepository>(),
        initialDeviceName: 'Thiết bị của tôi',
      ),
      child: JoinConfirmView(inviteRaw: inviteRaw),
    );
  }
}

class JoinConfirmView extends StatefulWidget {
  const JoinConfirmView({super.key, required this.inviteRaw});

  final String inviteRaw;

  @override
  State<JoinConfirmView> createState() => _JoinConfirmViewState();
}

class _JoinConfirmViewState extends State<JoinConfirmView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<JoinBloc>();
      final invite = InvitePayload.tryParse(widget.inviteRaw);
      if (invite == null) {
        DialogUtils.showInfoDialog(
          context: context,
          title: 'Mã mời không hợp lệ',
          message: 'Mã QR này không đúng định dạng. Hãy xin Owner một mã mời mới.',
        );
        return;
      }
      if (invite.isExpired) {
        DialogUtils.showInfoDialog(
          context: context,
          title: 'Mã mời đã hết hạn',
          message: 'Mã mời chỉ có hiệu lực 10 phút. Hãy xin Owner một mã mời mới.',
        );
        return;
      }
      bloc.add(JoinInviteScanned(invite));
      _showConfirmSheet();
    });
  }

  void _showConfirmSheet() {
    final bloc = context.read<JoinBloc>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: BlocConsumer<JoinBloc, JoinState>(
          listener: (context, state) {
            if (state.phase == JoinPhase.waitingApproval) {
              Navigator.of(dialogContext).pop();
            }
          },
          builder: (context, state) => _JoinConfirmDialog(state: state),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tham gia kênh')),
      body: BlocConsumer<JoinBloc, JoinState>(
        listener: (context, state) {
          if (state.phase == JoinPhase.approved) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        builder: (context, state) {
          return switch (state.phase) {
            JoinPhase.waitingApproval => _WaitingApprovalView(state: state),
            _ => _IdleView(onRescan: _showConfirmSheet),
          };
        },
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onRescan});

  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Chưa gửi yêu cầu tham gia nào'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRescan,
            icon: const Icon(Icons.refresh),
            label: const Text('Nhập lại mã mời'),
          ),
        ],
      ),
    );
  }
}

class _JoinConfirmDialog extends StatefulWidget {
  const _JoinConfirmDialog({required this.state});

  final JoinState state;

  @override
  State<_JoinConfirmDialog> createState() => _JoinConfirmDialogState();
}

class _JoinConfirmDialogState extends State<_JoinConfirmDialog> {
  late final TextEditingController _deviceNameController =
      TextEditingController(text: widget.state.deviceName);

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: DialogUtils.borderRadius),
      insetPadding: DialogUtils.insetPadding,
      titlePadding: DialogUtils.defaultTitlePadding,
      contentPadding: DialogUtils.defaultContentPadding,
      actionsPadding: DialogUtils.defaultActionsPadding,
      title: const Text('Tham gia kênh'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kênh: ${state.channelName.isEmpty ? "—" : state.channelName}'),
          const SizedBox(height: 4),
          Text(
            'Máy chủ: ${state.ownerDeviceName.isEmpty ? "—" : state.ownerDeviceName}',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceNameController,
            decoration: const InputDecoration(
              labelText: 'Tên thiết bị của bạn',
              border: OutlineInputBorder(),
            ),
            maxLength: 128,
            enabled: !state.isSubmitting,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: state.isSubmitting
              ? null
              : () => context.read<JoinBloc>().add(
                  JoinSubmitted(_deviceNameController.text.trim()),
                ),
          child: state.isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gửi yêu cầu kết nối'),
        ),
      ],
    );
  }
}

class _WaitingApprovalView extends StatelessWidget {
  const _WaitingApprovalView({required this.state});

  final JoinState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Đang chờ duyệt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.channelName.isEmpty
                  ? 'Yêu cầu đã được gửi tới máy chủ.'
                  : 'Đã gửi yêu cầu tham gia "${state.channelName}". Chờ máy chủ (Owner) duyệt.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy yêu cầu'),
              onPressed: () => _confirmCancel(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Hủy yêu cầu?',
      message: 'Yêu cầu tham gia kênh sẽ bị hủy. Owner sẽ không thấy yêu cầu này nữa.',
      confirmText: 'Hủy yêu cầu',
      cancelText: 'Tiếp tục chờ',
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );
    if (confirmed && context.mounted) {
      context.read<JoinBloc>().add(const JoinCancelled());
    }
  }
}
