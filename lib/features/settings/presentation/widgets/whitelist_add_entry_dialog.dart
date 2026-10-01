import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../bloc/whitelist_bloc.dart';
import '../bloc/whitelist_event.dart';

/// Dialog thêm địa chỉ mới vào white-list, kèm checkbox "Cho phép gửi OTP"
/// (mặc định tắt vì lý do an toàn).
class WhitelistAddEntryDialog extends StatefulWidget {
  const WhitelistAddEntryDialog({super.key});

  @override
  State<WhitelistAddEntryDialog> createState() =>
      _WhitelistAddEntryDialogState();
}

class _WhitelistAddEntryDialogState extends State<WhitelistAddEntryDialog> {
  final TextEditingController _addressController = TextEditingController();
  bool _allowOtp = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.addWhitelistDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _addressController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.addWhitelistHint,
            ),
            onSubmitted: (_) => _submit(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _allowOtp,
            title: Text(l10n.allowSendingOtp),
            onChanged: (value) => setState(() => _allowOtp = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  void _submit() {
    context.read<WhitelistBloc>().add(
          WhitelistEntryAdded(
            address: _addressController.text,
            allowOtp: _allowOtp,
          ),
        );
    Navigator.of(context).pop();
  }
}
