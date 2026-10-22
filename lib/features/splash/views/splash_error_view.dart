import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

/// Hiển thị khối báo lỗi và nút thử lại khi khởi tạo Splash gặp sự cố.
class SplashErrorView extends StatelessWidget {
  final String? errorMessage;
  final SplashFailureKind? failureKind;
  final VoidCallback? onRetry;

  const SplashErrorView({
    super.key,
    this.errorMessage,
    this.failureKind,
    this.onRetry,
  });

  void _handleRetry(BuildContext context) {
    if (onRetry != null) {
      onRetry!();
      return;
    }
    context.read<SplashBloc>().add(
      SplashRetried(
        defaultDeviceName: context.l10n.splashDefaultDeviceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final msg = errorMessage ?? '';
    final isNetwork = failureKind == SplashFailureKind.network;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNetwork ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            color: colorScheme.error,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            msg.isNotEmpty ? msg : l10n.splashConnectionError(''),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _handleRetry(context),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.splashRetry),
            ),
          ),
        ],
      ),
    );
  }
}
