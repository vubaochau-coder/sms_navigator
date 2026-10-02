import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../data/services/pair_management_service.dart';
import '../bloc/paired_receivers_bloc.dart';
import '../bloc/paired_receivers_event.dart';
import '../bloc/paired_senders_bloc.dart';
import '../bloc/paired_senders_event.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_state.dart';
import '../widgets/paired_devices_body.dart';
import '../widgets/pairing_add_device_dialog.dart';
import '../widgets/pairing_list_section.dart';

class PairingHubPage extends StatelessWidget {
  const PairingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = context.read<PairManagementService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<PairedReceiversBloc>(
          lazy: true,
          create: (_) =>
              PairedReceiversBloc(service)
                ..add(const PairedReceiversLoadEvent()),
        ),
        BlocProvider<PairedSendersBloc>(
          lazy: true,
          create: (_) =>
              PairedSendersBloc(service)..add(const PairedSendersLoadEvent()),
        ),
      ],
      child: BlocListener<PairingBloc, PairingState>(
        listenWhen: (previous, current) =>
            current.isSuccess && !previous.isSuccess,
        listener: (context, _) {
          // Ghép nối vừa hoàn tất (quét QR hoặc deep link) - làm mới
          // danh sách thiết bị để thiết bị mới xuất hiện ngay.
          context.read<PairedReceiversBloc>().add(
            const PairedReceiversLoadEvent(),
          );
          context.read<PairedSendersBloc>().add(const PairedSendersLoadEvent());
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.pairingHubTitle),
              actions: [
                Builder(
                  builder: (innerContext) {
                    return IconButton(
                      onPressed: () =>
                          PairingAddDeviceDialog.show(innerContext),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: l10n.pairingHubAddNew,
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: l10n.pairingHubTabReceivers),
                    Tab(text: l10n.pairingHubTabSenders),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      PairingListSection(
                        message: l10n.pairingHubReceiversDesc,
                        child: const PairedReceiversBody(),
                      ),
                      PairingListSection(
                        message: l10n.pairingHubSendersDesc,
                        child: const PairedSendersBody(),
                      ),
                    ],
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
