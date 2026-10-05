import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/dialog_utils.dart';
import '../bloc/join_bloc.dart';

/// Dialog xác nhận tham gia kênh: xem tên kênh, máy chủ và tùy chỉnh tên thiết bị.
class JoinConfirmDialog extends StatefulWidget {
  const JoinConfirmDialog({super.key, required this.state});

  final JoinState state;

  /// Helper mở modal dialog xác nhận tham gia kênh.
  static Future<void> show(BuildContext context) {
    final bloc = BlocProvider.of<JoinBloc>(context);
    return showDialog<void>(
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
          builder: (context, state) => JoinConfirmDialog(state: state),
        ),
      ),
    );
  }

  @override
  State<JoinConfirmDialog> createState() => _JoinConfirmDialogState();
}

class _JoinConfirmDialogState extends State<JoinConfirmDialog> {
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
    final l10n = context.l10n;
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: DialogUtils.borderRadius),
      insetPadding: DialogUtils.insetPadding,
      titlePadding: DialogUtils.defaultTitlePadding,
      contentPadding: DialogUtils.defaultContentPadding,
      actionsPadding: DialogUtils.defaultActionsPadding,
      title: Text(l10n.joinPageTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.joinChannelLabel(state.channelName.isEmpty ? '—' : state.channelName)),
            const SizedBox(height: 4),
            Text(
              l10n.joinOwnerLabel(state.ownerDeviceName.isEmpty ? '—' : state.ownerDeviceName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceNameController,
              decoration: InputDecoration(
                labelText: l10n.joinDeviceNameLabel,
                border: const OutlineInputBorder(),
              ),
              maxLength: 128,
              enabled: !state.isSubmitting,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(l10n.joinDismissAction),
        ),
        FilledButton(
          onPressed: state.isSubmitting
              ? null
              : () => BlocProvider.of<JoinBloc>(context).add(
                    JoinSubmitted(_deviceNameController.text.trim()),
                  ),
          child: state.isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.joinSendRequestAction),
        ),
      ],
    );
  }
}
