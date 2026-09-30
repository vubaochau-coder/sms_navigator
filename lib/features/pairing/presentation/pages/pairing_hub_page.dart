import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../data/services/pair_management_service.dart';
import 'paired_receivers_page.dart';
import 'paired_senders_page.dart';
import 'pairing_sender_page.dart';
import 'qr_scan_page.dart';

class PairingHubPage extends StatefulWidget {
  const PairingHubPage({super.key, this.pairManagementService});

  final PairManagementService? pairManagementService;

  @override
  State<PairingHubPage> createState() => _PairingHubPageState();
}

class _PairingHubPageState extends State<PairingHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _receiversReloadStamp = 0;
  int _sendersReloadStamp = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCreateQr() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PairingSenderPage()),
    );
    if (mounted) setState(() => _receiversReloadStamp++);
  }

  Future<void> _openScanQr() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (mounted) setState(() => _sendersReloadStamp++);
  }

  Future<void> _showAddDeviceDialog() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.pairingHubAddNew,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.pairingHubTitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AddDeviceOption(
                    icon: Icons.qr_code_rounded,
                    label: l10n.pairingHubAddReceiver,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _openCreateQr();
                    },
                  ),
                  const SizedBox(height: 10),
                  _AddDeviceOption(
                    icon: Icons.qr_code_scanner_rounded,
                    label: l10n.pairingHubAddSender,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _openScanQr();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pairingHubTitle),
        actions: [
          IconButton(
            onPressed: _showAddDeviceDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.pairingHubAddNew,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.pairingHubTabReceivers),
              Tab(text: l10n.pairingHubTabSenders),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PairingListSection(
                  message: l10n.pairingHubReceiversDesc,
                  child: PairedReceiversPage(
                    key: ValueKey<int>(_receiversReloadStamp),
                    pairManagementService: widget.pairManagementService,
                    showAppBar: false,
                  ),
                ),
                _PairingListSection(
                  message: l10n.pairingHubSendersDesc,
                  child: PairedSendersPage(
                    key: ValueKey<int>(_sendersReloadStamp),
                    pairManagementService: widget.pairManagementService,
                    showAppBar: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PairingListSection extends StatelessWidget {
  const _PairingListSection({required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Icon(
                Icons.priority_high_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _AddDeviceOption extends StatelessWidget {
  const _AddDeviceOption({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
