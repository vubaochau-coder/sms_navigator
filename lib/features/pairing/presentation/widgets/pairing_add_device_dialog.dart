import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../bloc/paired_receivers_bloc.dart';
import '../bloc/paired_receivers_event.dart';
import '../bloc/paired_senders_bloc.dart';
import '../bloc/paired_senders_event.dart';
import '../pages/pairing_sender_page.dart';
import '../pages/qr_scan_page.dart';

/// Dialog chọn loại ghép đôi (Tạo mã QR cho máy nhận hoặc Quét QR cho máy gửi).
class PairingAddDeviceDialog extends StatelessWidget {
  const PairingAddDeviceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return DialogUtils.showBaseForm<void>(
      BlocProvider.value(
        value: BlocProvider.of<PairedReceiversBloc>(context),
        child: BlocProvider.value(
          value: BlocProvider.of<PairedSendersBloc>(context),
          child: const PairingAddDeviceDialog(),
        ),
      ),
      context: context,
    );
  }

  Future<void> _openCreateQr(BuildContext context) async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PairingSenderPage()),
    );
    if (context.mounted) {
      BlocProvider.of<PairedReceiversBloc>(context).add(
        const PairedReceiversLoadEvent(),
      );
    }
  }

  Future<void> _openScanQr(BuildContext context) async {
    Navigator.of(context).pop();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (context.mounted) {
      BlocProvider.of<PairedSendersBloc>(context).add(
        const PairedSendersLoadEvent(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.pairingHubAddNew,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pairingHubTitle,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _AddDeviceOption(
              icon: Icons.qr_code_rounded,
              label: l10n.pairingHubAddReceiver,
              onTap: () => _openCreateQr(context),
            ),
            const SizedBox(height: 10),
            _AddDeviceOption(
              icon: Icons.qr_code_scanner_rounded,
              label: l10n.pairingHubAddSender,
              onTap: () => _openScanQr(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDeviceOption extends StatelessWidget {
  const _AddDeviceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
