import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/network/server_waker.dart';
import '../../../core/ui/toast_utils.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

/// Hiển thị khối báo lỗi và nút thử lại khi khởi tạo Splash gặp sự cố.
///
/// [SplashFailureKind.serverStarting]: thêm nút mở `/health` của Render bằng
/// trình duyệt (Custom Tab) — trình duyệt vượt được bước kiểm tra bot của
/// Render mà HTTP client của app có thể không. Quay lại app → tự Thử lại.
class SplashErrorView extends StatefulWidget {
  final String? errorMessage;
  final SplashFailureKind? failureKind;
  final VoidCallback? onRetry;

  /// Mở trang đánh thức; mặc định dùng [ServerWaker] + url_launcher. Trả
  /// `true` nếu đã mở được.
  final Future<bool> Function()? onWakeInBrowser;

  const SplashErrorView({
    super.key,
    this.errorMessage,
    this.failureKind,
    this.onRetry,
    this.onWakeInBrowser,
  });

  @override
  State<SplashErrorView> createState() => _SplashErrorViewState();
}

class _SplashErrorViewState extends State<SplashErrorView> with WidgetsBindingObserver {
  /// Đã mở trình duyệt, đang chờ người dùng quay lại app.
  bool _awaitingReturn = false;

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
    if (state == AppLifecycleState.resumed && _awaitingReturn && mounted) {
      _awaitingReturn = false;
      _handleRetry(context);
    }
  }

  void _handleRetry(BuildContext context) {
    if (widget.onRetry != null) {
      widget.onRetry!();
      return;
    }
    context.read<SplashBloc>().add(
      SplashRetried(
        defaultDeviceName: context.l10n.splashDefaultDeviceName,
      ),
    );
  }

  Future<bool> _defaultWakeInBrowser() async {
    final waker = context.read<ServerWaker>();
    // Lần thử lại sau khi quay về phải ping lại, không dùng kết quả "thất bại"
    // đang trong cooldown.
    waker.resetCooldown();
    return launchUrl(waker.wakeUri, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _handleWakeInBrowser(BuildContext context) async {
    final failedText = context.l10n.splashWakeInBrowserFailed;
    var opened = false;
    try {
      opened = await (widget.onWakeInBrowser ?? _defaultWakeInBrowser)();
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    if (opened) {
      _awaitingReturn = true;
    } else {
      ToastUtils.showToast(failedText, context: this.context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.errorMessage;
    final failureKind = widget.failureKind;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final msg = errorMessage ?? '';
    final icon = switch (failureKind) {
      SplashFailureKind.network => Icons.wifi_off_rounded,
      SplashFailureKind.maintenance => Icons.construction_rounded,
      SplashFailureKind.serverStarting => Icons.bedtime_rounded,
      _ => Icons.cloud_off_rounded,
    };

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
            icon,
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
          if (failureKind == SplashFailureKind.serverStarting) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _handleWakeInBrowser(context),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: Text(l10n.splashWakeInBrowser),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
