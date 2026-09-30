import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../otp_list/presentation/pages/otp_list_page.dart';
import '../../../pairing/presentation/pages/pairing_hub_page.dart';
import '../../../pairing/presentation/pages/qr_scan_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  void _openQrScanner() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QrScanPage()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const OtpListPage(),
          const PairingHubPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQrScanner,
        tooltip: l10n.pairingHubScanQr,
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
              color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.black)
                  .withValues(alpha: 0.10),
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
                  icon: Icons.sms_rounded,
                  label: l10n.navTabSms,
                  selected: _selectedIndex == 0,
                  onTap: () => _selectTab(0),
                ),
              ),
              const SizedBox(width: 56),
              Expanded(
                child: _MainNavTab(
                  icon: Icons.phonelink_setup_rounded,
                  label: l10n.navTabPairing,
                  selected: _selectedIndex == 1,
                  onTap: () => _selectTab(1),
                ),
              ),
            ],
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
