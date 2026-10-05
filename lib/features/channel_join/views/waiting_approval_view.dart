import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/dialog_utils.dart';
import '../bloc/join_bloc.dart';

/// Màn hình chờ duyệt yêu cầu tham gia kênh với nút hủy yêu cầu.
class WaitingApprovalView extends StatelessWidget {
  const WaitingApprovalView({super.key, required this.state});

  final JoinState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              l10n.joinWaitingApprovalTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.channelName.isEmpty
                  ? l10n.joinWaitingApprovalMessage
                  : l10n.joinWaitingApprovalChannelMessage(state.channelName),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(l10n.joinCancelRequestAction),
              onPressed: () => _confirmCancel(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: l10n.joinCancelConfirmTitle,
      message: l10n.joinCancelConfirmMessage,
      confirmText: l10n.joinCancelRequestAction,
      cancelText: l10n.joinContinueWaitingAction,
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );
    if (confirmed && context.mounted) {
      BlocProvider.of<JoinBloc>(context).add(const JoinCancelled());
    }
  }
}
