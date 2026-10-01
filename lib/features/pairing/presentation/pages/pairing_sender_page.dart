import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/dimens.dart';
import '../../../device/data/repositories/device_setup_repository.dart';
import '../../../device/presentation/bloc/device_setup_bloc.dart';
import '../../../device/presentation/bloc/device_setup_event.dart';
import '../../../device/presentation/bloc/device_setup_state.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_event.dart';
import '../bloc/pairing_state.dart';

class PairingSenderPage extends StatelessWidget {
  const PairingSenderPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<PairingBloc>().add(const PairingGenerateSenderCodeEvent());
    return BlocProvider(
      create: (_) =>
          DeviceSetupBloc(repository: context.read<DeviceSetupRepository>())
            ..add(const DeviceSetupStarted()),
      child: const _PairingSenderView(),
    );
  }
}

class _PairingSenderView extends StatefulWidget {
  const _PairingSenderView();

  @override
  State<_PairingSenderView> createState() => _PairingSenderViewState();
}

class _PairingSenderViewState extends State<_PairingSenderView> {
  bool _permissionPromptShown = false;

  void _maybeShowSmsPermissionPrompt(DeviceSetupState state) {
    if (_permissionPromptShown) return;
    if (state.isLoading) return;
    if (state.smsPermissionGranted != false) return;
    _permissionPromptShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cần quyền đọc SMS'),
          content: const Text(
            'Để máy này nhận diện và chuyển tiếp SMS OTP từ mọi ứng dụng khác, '
            'SMS Navigator cần quyền đọc tin nhắn. Bạn có thể cấp ngay bây giờ.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Để Sau'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<DeviceSetupBloc>().add(
                  state.smsPermissionPermanentlyDenied
                      ? const DeviceSetupAppSettingsOpened()
                      : const DeviceSetupSmsPermissionRequested(),
                );
              },
              child: Text(state.smsPermissionPermanentlyDenied
                  ? 'Mở Cài Đặt'
                  : 'Cấp Quyền Ngay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ghép Đôi Thiết Bị')),
      body: BlocListener<DeviceSetupBloc, DeviceSetupState>(
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeShowSmsPermissionPrompt(state);
          });
        },
        child: BlocBuilder<PairingBloc, PairingState>(
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
                  const _SmsPermissionBanner(),
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
    final borderRadius = BorderRadius.circular(12);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRegenerate,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Làm Mới'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            ),
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

class _SmsPermissionBanner extends StatefulWidget {
  const _SmsPermissionBanner();

  @override
  State<_SmsPermissionBanner> createState() => _SmsPermissionBannerState();
}

class _SmsPermissionBannerState extends State<_SmsPermissionBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DeviceSetupBloc>().add(const DeviceSetupStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceSetupBloc, DeviceSetupState>(
      builder: (context, state) {
        if (state.smsPermissionGranted != false) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade900,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chưa cấp quyền đọc SMS — tính năng chuyển tiếp OTP đang tạm dừng.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  context.read<DeviceSetupBloc>().add(
                    state.smsPermissionPermanentlyDenied
                        ? const DeviceSetupAppSettingsOpened()
                        : const DeviceSetupSmsPermissionRequested(),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  state.smsPermissionPermanentlyDenied
                      ? 'Mở Cài Đặt'
                      : 'Cấp Quyền',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
