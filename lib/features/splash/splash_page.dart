import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/enums/splash_status.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/channel_key_store.dart';
import '../../core/services/crashlytics_service.dart';
import '../../core/services/device_api_service.dart';
import '../../core/services/device_storage_service.dart';
import '../../core/services/fcm_notification_service.dart';
import '../../core/services/native_relay_service.dart';
import '../../core/services/startup_reconcile_service.dart';
import '../backup/backup_restore_page.dart';
import '../home/main_navigation_page.dart';
import 'bloc/splash_bloc.dart';
import 'bloc/splash_event.dart';
import 'bloc/splash_state.dart';

/// Màn hình Splash / Khởi tạo & Kiểm tra đăng ký thiết bị theo kiến trúc BLoC.
class SplashPage extends StatelessWidget {
  final bool autoStart;
  final VoidCallback? onCompleted;

  const SplashPage({
    super.key,
    this.autoStart = true,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final defaultDeviceName = context.l10n.splashDefaultDeviceName;

    return BlocProvider(
      create: (ctx) {
        final bloc = SplashBloc(
          crashlyticsService: ctx.read<CrashlyticsService>(),
          analyticsService: ctx.read<AnalyticsService>(),
          fcmService: ctx.read<FcmNotificationService>(),
          deviceStorageService: ctx.read<DeviceStorageService>(),
          keyStore: ctx.read<ChannelKeyStore>(),
          deviceApiService: ctx.read<DeviceApiService>(),
          startupReconcileService: ctx.read<StartupReconcileService>(),
          nativeRelayService: ctx.read<NativeRelayService>(),
          offerRestoreOnFirstRun: true,
        );
        if (autoStart) {
          bloc.add(SplashStarted(
            defaultDeviceName: defaultDeviceName,
          ));
        }
        return bloc;
      },
      child: _SplashView(onCompleted: onCompleted),
    );
  }
}

class _SplashView extends StatefulWidget {
  final VoidCallback? onCompleted;

  const _SplashView({this.onCompleted});

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToMain(BuildContext context) {
    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  String _getStatusText(BuildContext context, SplashStatus status) {
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
    final l10n = context.l10n;

    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state.isReady) {
          _navigateToMain(context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // App Logo Hero với hiệu ứng pulse
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.32),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.sms_rounded,
                          size: 52,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tên ứng dụng & phụ đề bản địa hóa
                    Text(
                      AppStrings.appTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.splashSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(flex: 2),

                    // Lần mở đầu: chọn thiết lập mới / khôi phục (BACKLOG 1.1),
                    // trạng thái tiến trình, hoặc khối báo lỗi
                    if (state.isAwaitingSetupChoice) ...[
                      const _SetupChoice(),
                    ] else if (!state.isFailure) ...[
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
                        _getStatusText(context, state.status),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Builder(
                        builder: (context) {
                          final msg = state.errorMessage ?? '';
                          final isNetwork = msg.toLowerCase().contains('kết nối') ||
                              msg.toLowerCase().contains('mạng') ||
                              msg.toLowerCase().contains('timeout');

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
                              children: [
                                Icon(
                                  isNetwork
                                      ? Icons.wifi_off_rounded
                                      : Icons.cloud_off_rounded,
                                  color: colorScheme.error,
                                  size: 36,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  msg.isNotEmpty
                                      ? msg
                                      : l10n.splashConnectionError(''),
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
                                    onPressed: () {
                                      context.read<SplashBloc>().add(
                                        SplashRetried(
                                          defaultDeviceName:
                                              l10n.splashDefaultDeviceName,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: Text(l10n.splashRetry),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lựa chọn ở lần mở đầu tiên: tạo danh tính mới hay khôi phục `.smsnav`.
class _SetupChoice extends StatelessWidget {
  const _SetupChoice();

  Future<void> _restore(BuildContext context) async {
    final bloc = context.read<SplashBloc>();
    final defaultName = context.l10n.splashDefaultDeviceName;
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BackupRestorePage()),
    );
    // Đã có device token từ bản sao lưu → chạy lại bootstrap (nhánh xác thực).
    if (restored == true) bloc.add(SplashRetried(defaultDeviceName: defaultName));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.splashSetupChoiceTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _ChoiceButton(
          icon: Icons.add_moderator_rounded,
          title: l10n.splashSetupNewDevice,
          subtitle: l10n.splashSetupNewDeviceSubtitle,
          primary: true,
          onPressed: () => context.read<SplashBloc>().add(
            SplashNewDeviceChosen(defaultDeviceName: l10n.splashDefaultDeviceName),
          ),
        ),
        const SizedBox(height: 12),
        _ChoiceButton(
          icon: Icons.settings_backup_restore_rounded,
          title: l10n.splashSetupRestore,
          subtitle: l10n.splashSetupRestoreSubtitle,
          onPressed: () => _restore(context),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = primary ? colorScheme.onPrimary : colorScheme.primary;
    final child = Row(
      children: [
        Icon(icon, color: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: foreground)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: foreground.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ],
    );
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return primary
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(padding: padding, shape: shape),
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(padding: padding, shape: shape),
            child: child,
          );
  }
}
