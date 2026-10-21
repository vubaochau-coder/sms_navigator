import 'package:flutter/material.dart';

import '../../../core/crypto/backup_crypto.dart';
import '../../../core/extensions/context_extensions.dart';

/// Hộp thoại đặt mật khẩu cho bản sao lưu (nhập 2 lần). Trả về mật khẩu,
/// hoặc `null` nếu huỷ.
Future<String?> showBackupPassphraseDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _BackupPassphraseDialog(),
  );
}

class _BackupPassphraseDialog extends StatefulWidget {
  const _BackupPassphraseDialog();

  @override
  State<_BackupPassphraseDialog> createState() => _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<_BackupPassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passphrase = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_passphrase.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.backupPassphraseTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.backupPassphraseMessage, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                l10n.backupExportWarning,
                style: TextStyle(fontSize: 12, color: colorScheme.error),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passphrase,
                obscureText: _obscure,
                autofocus: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.backupPassphraseLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? l10n.backupShowPassphrase : l10n.backupHidePassphrase,
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) => (value ?? '').length < BackupCrypto.minPassphraseLength
                    ? l10n.backupPassphraseTooShort(BackupCrypto.minPassphraseLength)
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.backupPassphraseConfirmLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value != _passphrase.text ? l10n.backupPassphraseMismatch : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.backupExportConfirm)),
      ],
    );
  }
}
