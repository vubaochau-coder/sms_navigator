import 'package:flutter/material.dart';

import '../../../core/enums/splash_status.dart';
import '../../../core/extensions/context_extensions.dart';

/// Hiển thị spinner và trạng thái tiến trình khởi tạo/đồng bộ của ứng dụng.
class SplashProgressView extends StatelessWidget {
  final SplashStatus status;

  const SplashProgressView({
    super.key,
    required this.status,
  });

  /// Chuyển đổi trạng thái [SplashStatus] sang chuỗi thông báo bản địa hóa.
  static String getStatusText(BuildContext context, SplashStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case SplashStatus.initial:
      case SplashStatus.initializingServices:
        return l10n.splashInitializingServices;
      case SplashStatus.checkingIdentityKey:
        return l10n.splashCheckingIdentityKey;
      case SplashStatus.authenticatingDevice:
        return l10n.splashAuthenticatingDevice;
      case SplashStatus.awaitingSetupChoice:
        return l10n.splashSetupChoiceTitle;
      case SplashStatus.registeringDevice:
        return l10n.splashRegisteringDevice;
      case SplashStatus.syncingChannels:
        return l10n.splashSyncingChannels;
      case SplashStatus.ready:
        return l10n.splashReady;
      case SplashStatus.failure:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          getStatusText(context, status),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
