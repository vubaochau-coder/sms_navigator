import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../channel/data/services/startup_reconcile_service.dart';
import '../../../channel/presentation/pages/channel_list_page.dart';
import '../../../channel/presentation/pages/join_qr_scan_page.dart';
import '../../../channel/presentation/pages/otp_by_date_page.dart';
import '../../../device/data/repositories/device_setup_repository.dart';
import '../../../device/presentation/bloc/device_setup_bloc.dart';
import '../../../device/presentation/bloc/device_setup_event.dart';
import '../../../device/presentation/bloc/device_setup_state.dart';
import '../../../device/presentation/dialogs/sms_permission_prompt_dialog.dart';

/// Main navigation (kiến trúc mới):
/// - Tab 0: OTP theo ngày (gộp mọi kênh, 6.1–6.4);
/// - Tab 1: Kênh (2 nhóm "Kênh của bạn" / "Kênh bạn tham gia", 2.1);
/// - FAB: quét QR mời (3.1);
/// - Khi mở app: startup reconcile ngầm (SRD 7.3) + gate SMS permission.
class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DeviceSetupBloc(repository: context.read<DeviceSetupRepository>())
            ..add(const DeviceSetupStarted()),
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
  int _selectedIndex = 0;
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

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const JoinQrScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    _runStartupReconcile();
    return BlocListener<DeviceSetupBloc, DeviceSetupState>(
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeShowSmsPermissionPrompt(state);
        });
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            OtpByDatePage(),
            ChannelListPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openQrScanner,
          tooltip: 'Quét mã mời',
          shape: const CircleBorder(),
          elevation: 8,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: const Icon(Icons.qr_code_scanner_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: DecoratedBox(
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
                  child: _MainNavTab(
                    icon: Icons.password_rounded,
                    label: 'OTP',
                    selected: _selectedIndex == 0,
                    onTap: () => _selectTab(0),
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  child: _MainNavTab(
                    icon: Icons.hub_rounded,
                    label: 'Kênh',
                    selected: _selectedIndex == 1,
                    onTap: () => _selectTab(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _MainNavTab extends StatelessWidget {
  const _MainNavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
