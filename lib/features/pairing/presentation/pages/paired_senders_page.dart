import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/pair_management_service.dart';
import '../bloc/paired_senders_bloc.dart';
import '../bloc/paired_senders_event.dart';
import '../widgets/paired_senders_body.dart';

/// Màn hình xem danh sách thiết bị gửi dành cho Máy Nhận (Receiver).
class PairedSendersPage extends StatelessWidget {
  const PairedSendersPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    try {
      context.read<PairedSendersBloc>();
      return PairedSendersBody(showAppBar: showAppBar);
    } catch (_) {
      final service = context.read<PairManagementService>();

      return BlocProvider(
        create: (_) => PairedSendersBloc(service)
          ..add(const PairedSendersLoadEvent()),
        child: PairedSendersBody(showAppBar: showAppBar),
      );
    }
  }
}
