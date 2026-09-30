import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pairingHubTitle),
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final isReceiversTab = _tabController.index == 0;
              return TextButton.icon(
                onPressed: isReceiversTab ? _openCreateQr : _openScanQr,
                icon: Icon(
                  isReceiversTab
                      ? Icons.qr_code_rounded
                      : Icons.qr_code_scanner_rounded,
                ),
                label: Text(
                  isReceiversTab
                      ? l10n.pairingHubCreateQr
                      : l10n.pairingHubScanQr,
                ),
              );
            },
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
                  icon: Icons.arrow_upward_rounded,
                  message: l10n.pairingHubReceiversDesc,
                  child: PairedReceiversPage(
                    key: ValueKey<int>(_receiversReloadStamp),
                    pairManagementService: widget.pairManagementService,
                    showAppBar: false,
                  ),
                ),
                _PairingListSection(
                  icon: Icons.arrow_downward_rounded,
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
  const _PairingListSection({
    required this.icon,
    required this.message,
    required this.child,
  });

  final IconData icon;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
