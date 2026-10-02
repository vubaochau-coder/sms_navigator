import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_event.dart';
import '../bloc/pairing_state.dart';

/// Trang xác nhận ghép đôi khi app được mở qua deep link (GĐ3).
///
/// Payload QR đã có sẵn trong URL nên không cần mở scanner: đẩy sự kiện
/// submit vào [PairingBloc] toàn cục ngay khi mở trang và hiển thị kết quả.
class PairingDeepLinkConfirmPage extends StatefulWidget {
  const PairingDeepLinkConfirmPage({super.key, required this.qrData});

  final String qrData;

  @override
  State<PairingDeepLinkConfirmPage> createState() =>
      _PairingDeepLinkConfirmPageState();
}

class _PairingDeepLinkConfirmPageState
    extends State<PairingDeepLinkConfirmPage> {
  @override
  void initState() {
    super.initState();
    context.read<PairingBloc>().add(
      PairingSubmitReceiverQrEvent(widget.qrData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deeplinkPairingTitle)),
      body: SafeArea(
        child: BlocBuilder<PairingBloc, PairingState>(
          builder: (context, state) {
            if (state.isSuccess) {
              return _ResultView(
                icon: Icons.check_circle_rounded,
                iconColor: colorScheme.primary,
                title: context.l10n.deeplinkPairingSuccess,
                buttonLabel: context.l10n.done,
                onButtonPressed: () => Navigator.of(context).pop(),
              );
            }
            if (state.errorMessage != null) {
              return _ResultView(
                icon: Icons.error_rounded,
                iconColor: colorScheme.error,
                title: context.l10n.deeplinkPairingFailed,
                message: state.errorMessage,
                buttonLabel: context.l10n.close,
                onButtonPressed: () => Navigator.of(context).pop(),
              );
            }
            return _ResultView(
              icon: Icons.sync_rounded,
              iconColor: colorScheme.primary,
              title: context.l10n.deeplinkPairingInProgress,
              showSpinner: true,
            );
          },
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.buttonLabel,
    this.onButtonPressed,
    this.showSpinner = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (showSpinner) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onButtonPressed,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
