import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/dimens.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_event.dart';
import '../bloc/pairing_state.dart';

class PairingSenderPage extends StatelessWidget {
  const PairingSenderPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<PairingBloc>().add(const PairingGenerateSenderCodeEvent());
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ghép Đôi Thiết Bị')),
      body: BlocBuilder<PairingBloc, PairingState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final payload = state.pairingPayload;
          if (payload == null) {
            return _ErrorView(
              message: state.errorMessage ?? 'Không thể tạo mã ghép đôi.',
              onRetry: () {
                context.read<PairingBloc>().add(
                  const PairingGenerateSenderCodeEvent(),
                );
              },
            );
          }

          return SingleChildScrollView(
            padding: Dimens.screenPadding,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const _HeaderIcon(),
                const SizedBox(height: 24),
                Text('Mã QR Ghép Đôi', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Dùng Thiết Bị Nhận để quét mã QR bên dưới, thiết lập kênh E2EE an toàn tức thì.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Hero(
                  tag: 'pairing_qr_hero',
                  child: _QrCard(qrData: payload.toQrData()),
                ),
                const SizedBox(height: 16),
                _CountdownChip(seconds: state.countdownSeconds),
                const SizedBox(height: 24),
                const _E2eeBadge(),
                const SizedBox(height: 32),
                _ActionButtons(
                  onRegenerate: () {
                    context.read<PairingBloc>().add(
                      const PairingGenerateSenderCodeEvent(),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 38),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 240,
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        size: 200,
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.seconds});

  final int seconds;

  String get _label {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrgent = seconds <= 60;
    final foreground = isUrgent
        ? colorScheme.onError
        : colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? colorScheme.error : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _E2eeBadge extends StatelessWidget {
  const _E2eeBadge();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          'Mã hóa đầu cuối AES-256-GCM',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onRegenerate});

  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Làm Mới Mã QR'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hoàn Tất'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Thử Lại')),
          ],
        ),
      ),
    );
  }
}
