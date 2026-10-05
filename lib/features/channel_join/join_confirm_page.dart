import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/models/pairing_session_model.dart';
import '../../core/repositories/join_channel_repository.dart';
import '../../core/utils/dialog_utils.dart';
import 'bloc/join_bloc.dart';
import 'views/join_confirm_dialog.dart';
import 'views/join_idle_view.dart';
import 'views/waiting_approval_view.dart';

export 'views/join_confirm_dialog.dart';
export 'views/join_idle_view.dart';
export 'views/waiting_approval_view.dart';

/// Đích đến sau khi quét QR invite v4 (3.1→3.6):
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
        initialDeviceName: context.l10n.splashDefaultDeviceName,
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
      if (!mounted) return;
      final bloc = BlocProvider.of<JoinBloc>(context);
      final l10n = context.l10n;
      final invite = InvitePayload.tryParse(widget.inviteRaw);
      if (invite == null) {
        DialogUtils.showInfoDialog(
          context: context,
          title: l10n.joinInvalidInviteTitle,
          message: l10n.joinInvalidInviteMessage,
        );
        return;
      }
      if (invite.isExpired) {
        DialogUtils.showInfoDialog(
          context: context,
          title: l10n.joinExpiredInviteTitle,
          message: l10n.joinExpiredInviteMessage,
        );
        return;
      }
      bloc.add(JoinInviteScanned(invite));
      JoinConfirmDialog.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinPageTitle)),
      body: BlocConsumer<JoinBloc, JoinState>(
        listener: (context, state) {
          if (state.phase == JoinPhase.approved) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        builder: (context, state) {
          return switch (state.phase) {
            JoinPhase.waitingApproval => WaitingApprovalView(state: state),
            _ => JoinIdleView(onRescan: () => JoinConfirmDialog.show(context)),
          };
        },
      ),
    );
  }
}
