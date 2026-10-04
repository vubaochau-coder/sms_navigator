import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../../core/services/device_storage_service.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../channel/data/services/channel_key_store.dart';
import '../../../channel/data/services/startup_reconcile_service.dart';
import '../../../device/data/services/device_api_service.dart';
import '../../../home/presentation/pages/main_navigation_page.dart';

/// Màn hình Splash / Khởi tạo & Kiểm tra đăng ký thiết bị.
///
/// Hoạt động như màn hình flash screen khởi động:
/// 1. Khởi tạo các dịch vụ ngầm (Crashlytics, Analytics, FCM);
/// 2. Kiểm tra định danh mật mã (Identity Key Pair);
/// 3. Kiểm tra trạng thái đăng ký của thiết bị (tự động đăng ký với máy chủ nếu chưa có token);
/// 4. Đồng bộ FCM Token và chạy Startup Reconcile các kênh E2EE;
/// 5. Chuyển tiếp mượt mà vào [MainNavigationPage] khi hoàn tất;
/// 6. Hiển thị thông báo lỗi & nút Thử lại / Chế độ ngoại tuyến nếu gặp sự cố mạng.
class SplashPage extends StatefulWidget {
  final bool autoStart;
  final VoidCallback? onCompleted;

  const SplashPage({
    super.key,
    this.autoStart = true,
    this.onCompleted,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  String _statusMessage = 'Đang khởi tạo ứng dụng...';
  String? _errorMessage;

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

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startBootstrap();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startBootstrap() async {
    setState(() {
      _errorMessage = null;
      _statusMessage = 'Đang khởi tạo các dịch vụ...';
    });

    try {
      final crashlytics = context.read<CrashlyticsService>();
      final analytics = context.read<AnalyticsService>();
      final fcm = context.read<FcmNotificationService>();
      final deviceStorage = context.read<DeviceStorageService>();
      final keyStore = context.read<ChannelKeyStore>();
      final deviceApi = context.read<DeviceApiService>();
      final reconcileService = context.read<StartupReconcileService>();

      // 1. Dịch vụ báo cáo & telemetry
      await crashlytics.initialize();
      analytics.initialize();

      // 2. Dịch vụ chuông FCM
      fcm.initialize();

      // 3. Khởi tạo & kiểm tra cặp khóa định danh thiết bị (Identity Key)
      if (mounted) {
        setState(() => _statusMessage = 'Đang kiểm tra khóa định danh thiết bị...');
      }
      await keyStore.getOrCreateIdentityKeyPair();

      // 4. Kiểm tra trạng thái đăng ký thiết bị với máy chủ
      if (mounted) {
        setState(() => _statusMessage = 'Đang xác thực thiết bị với máy chủ...');
      }
      final deviceToken = await deviceStorage.getDeviceToken();
      if (deviceToken == null || deviceToken.isEmpty) {
        if (mounted) {
          setState(() => _statusMessage = 'Đang đăng ký thiết bị mới...');
        }
        await deviceApi.registerDevice(
          deviceName: 'Thiết bị của tôi',
          platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        );
      }

      // 5. Đồng bộ FCM token chuông
      try {
        await fcm.syncToken();
      } catch (e) {
        debugPrint('[Splash] FCM syncToken warning: $e');
      }

      // 6. Startup reconcile các kênh & quyền truy cập
      if (mounted) {
        setState(() => _statusMessage = 'Đang đồng bộ dữ liệu kênh...');
      }
      try {
        await reconcileService.reconcile();
      } catch (e) {
        debugPrint('[Splash] Startup reconcile warning: $e');
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'Sẵn sàng!';
        });
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      _navigateToMain();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể kết nối hoặc xác thực thiết bị: $error';
      });
    }
  }

  void _navigateToMain() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Logo Hero với hiệu ứng pulse mượt mà
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

                // Tên ứng dụng & phụ đề
                Text(
                  AppStrings.appTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ghép đôi và đồng bộ SMS an toàn',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                // Trạng thái / Tiến trình hoặc Thông báo lỗi
                if (_errorMessage == null) ...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _statusMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Container(
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
                        Icon(Icons.wifi_off_rounded, color: colorScheme.error, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
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
                            onPressed: _startBootstrap,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _navigateToMain,
                          child: const Text('Bỏ qua & Vào chế độ ngoại tuyến'),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
