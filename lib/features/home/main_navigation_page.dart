import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/repositories/app_update_repository.dart';
import '../../core/repositories/device_setup_repository.dart';
import '../../core/services/startup_reconcile_service.dart';
import '../../core/utils/qr_link_parser.dart';
import '../../core/ui/toast_utils.dart';
import '../../core/repositories/activity_repository.dart';
import '../activity/activity_page.dart';
import '../activity/bloc/activity_cubit.dart';
import '../channel/channel_page.dart';
import '../../core/bloc/qr_ingress/qr_ingress_cubit.dart';
import '../qr_entry/qr_entry_page.dart';
import '../scanner/qr_scan_page.dart';
import '../sms/sms_page.dart';
import '../device/bloc/device_setup_bloc.dart';
import '../device/bloc/device_setup_event.dart';
import '../device/bloc/device_setup_state.dart';
import '../device/device_profile_page.dart';
import '../device/views/sms_permission_prompt_dialog.dart';
import 'bloc/home_tab_cubit.dart';
import 'views/main_nav_tab.dart';
import 'views/app_update_dialog.dart';
import '../../core/extensions/context_extensions.dart';

/// Main navigation (kiến trúc mới):
/// - Tab 0: SMS theo ngày (gộp mọi kênh, 6.1–6.4);
/// - Tab 1: Kênh (2 nhóm "Kênh của bạn" / "Kênh bạn tham gia", 2.1);
/// - Tab 2: Hoạt động (nhật ký relay SMS + sự kiện kênh);
/// - Tab 3: Thiết bị (hồ sơ, tình trạng quyền, sao lưu, tuỳ chọn);
/// - FAB: quét QR mời (3.1);
/// - Khi mở app: startup reconcile ngầm (SRD 7.3) + gate SMS permission.
class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            return DeviceSetupBloc(repository: context.read<DeviceSetupRepository>())
                ..add(const DeviceSetupStarted());
          },
        ),
        BlocProvider(create: (_) => HomeTabCubit()),
        BlocProvider(
          create: (_) => ActivityCubit(repository: context.read<ActivityRepository>()),
        ),
      ],
      child: const _MainNavigationView(),
    );
  }
}

class _MainNavigationView extends StatefulWidget {
  const _MainNavigationView();

  @override
  State<_MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<_MainNavigationView> {
  bool _smsPromptShown = false;
  bool _reconcileStarted = false;

  void _maybeShowSmsPermissionPrompt(DeviceSetupState state) {
    if (_smsPromptShown) return;
    if (state.isLoading) return;
    if (!state.smsPromptNeeded) return;
    if (state.smsPermissionGranted != false) return;
    _smsPromptShown = true;
    showSmsPermissionPromptDialog(
      context,
      permanentlyDenied: state.smsPermissionPermanentlyDenied,
    );
  }

  /// Startup reconcile (SRD 7.3): channel state + request state + provisioned
  /// key — chạy ngầm một lần khi mở app, không có UI riêng.
  void _runStartupReconcile() {
    if (_reconcileStarted) return;
    _reconcileStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StartupReconcileService>().reconcile();
    });
  }

  bool _updateCheckStarted = false;

  /// Kiểm tra phiên bản mới từ Firebase Remote Config và hiện popup nếu có.
  void _checkAppUpdate() {
    if (_updateCheckStarted) return;
    _updateCheckStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final updateRepo = context.read<AppUpdateRepository>();
        final updateInfo = await updateRepo.checkForUpdate();
        if (updateInfo == null || !mounted) return;

        // Nếu không phải force update và người dùng đã chọn "Để sau" cho build này thì bỏ qua
        if (!updateInfo.isForceUpdate &&
            updateRepo.isUpdateDismissed(updateInfo.latestBuild)) {
          return;
        }

        if (!mounted) return;
        await AppUpdateDialog.show(context, updateInfo, updateRepo);
      } catch (e) {
        debugPrint('Check app update error: $e');
      }
    });
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push<ScanQrResult>(
      MaterialPageRoute(
        builder: (_) => const QrScanPage(),
      ),
    );
    if (!mounted || result == null) return;
    // Mọi nguồn mã đi chung một cổng (roadmap v3.3 §1).
    await context.read<QrIngressCubit>().submit(result.rawValue);
  }

  @override
  void initState() {
    super.initState();
    // Deeplink đến lúc Splash còn chạy (cold start / mid-splash) đang chờ sẵn.
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingQr());
  }

  void _consumePendingQr() {
    if (!mounted) return;
    final link = context.read<QrIngressCubit>().consume();
    if (link == null) return;
    final route = switch (link) {
      OpaqueQrLink(:final code) => MaterialPageRoute<void>(builder: (_) => QrEntryPage(code: code)),
    };
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    _runStartupReconcile();
    _checkAppUpdate();
    return MultiBlocListener(
      listeners: [
        BlocListener<DeviceSetupBloc, DeviceSetupState>(
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _maybeShowSmsPermissionPrompt(state);
            });
          },
        ),
        BlocListener<HomeTabCubit, HomeTab>(
          listenWhen: (previous, current) => current == HomeTab.activity,
          listener: (context, _) => context.read<ActivityCubit>().refresh(),
        ),
        BlocListener<QrIngressCubit, QrIngressState>(
          listenWhen: (previous, current) =>
              current.pending != null && current.pendingSeq != previous.pendingSeq,
          listener: (context, state) => _consumePendingQr(),
        ),
        BlocListener<QrIngressCubit, QrIngressState>(
          listenWhen: (previous, current) => current.rejectionSeq != previous.rejectionSeq,
          listener: (context, state) {
            final message = state.rejectionMessage;
            if (message != null) ToastUtils.showError(message);
          },
        ),
      ],
      child: BlocBuilder<HomeTabCubit, HomeTab>(
        builder: (context, tab) => _MainScaffold(tab: tab, onScan: _openQrScanner),
      ),
    );
  }
}

/// Khung màn chính: các tab giữ trạng thái (IndexedStack), FAB quét QR ở giữa.
class _MainScaffold extends StatelessWidget {
  const _MainScaffold({required this.tab, required this.onScan});

  final HomeTab tab;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          SmsPage(),
          ChannelPage(),
          ActivityPage(),
          DeviceProfilePage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_navigation_qr_scan_fab',
        onPressed: onScan,
        tooltip: context.l10n.scanInviteTooltip,
        shape: const CircleBorder(),
        elevation: 8,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _MainBottomBar(tab: tab),
    );
  }
}

class _MainBottomBar extends StatelessWidget {
  const _MainBottomBar({required this.tab});

  final HomeTab tab;

  @override
  Widget build(BuildContext context) {
    final tabs = context.read<HomeTabCubit>();
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        elevation: 0,
        child: Row(
          children: [
            Expanded(
              child: MainNavTab(
                icon: Icons.sms_outlined,
                label: context.l10n.smsPageTitle,
                selected: tab == HomeTab.sms,
                onTap: () => tabs.select(HomeTab.sms),
              ),
            ),
            Expanded(
              child: MainNavTab(
                icon: Icons.hub_rounded,
                label: context.l10n.channelPageTitle,
                selected: tab == HomeTab.channels,
                onTap: () => tabs.select(HomeTab.channels),
              ),
            ),
            // Chừa chỗ cho FAB quét QR
            const SizedBox(width: 56),
            Expanded(
              child: MainNavTab(
                icon: Icons.timeline_rounded,
                label: context.l10n.activityTabTitle,
                selected: tab == HomeTab.activity,
                onTap: () => tabs.select(HomeTab.activity),
              ),
            ),
            Expanded(
              child: _DeviceNavTab(
                selected: tab == HomeTab.device,
                onTap: () => tabs.select(HomeTab.device),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab Thiết bị: chấm xanh = đủ quyền, cam = cần chú ý (thay nút trên AppBar cũ).
class _DeviceNavTab extends StatelessWidget {
  const _DeviceNavTab({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceSetupBloc, DeviceSetupState>(
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.isAllCriticalStepsDone != current.isAllCriticalStepsDone,
      builder: (context, state) => MainNavTab(
        icon: Icons.phone_android_rounded,
        label: context.l10n.deviceTabTitle,
        selected: selected,
        onTap: onTap,
        badgeColor: state.isLoading
            ? null
            : (state.isAllCriticalStepsDone ? AppColors.success : AppColors.warning),
      ),
    );
  }
}
