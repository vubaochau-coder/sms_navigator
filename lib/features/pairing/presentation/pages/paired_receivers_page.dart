import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/pair_management_service.dart';
import '../bloc/paired_receivers_bloc.dart';
import '../bloc/paired_receivers_event.dart';
import '../widgets/paired_receivers_body.dart';

/// Màn hình quản lý danh sách thiết bị nhận dành cho Máy Gửi (Sender).
class PairedReceiversPage extends StatelessWidget {
  const PairedReceiversPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    try {
      context.read<PairedReceiversBloc>();
      return PairedReceiversBody(showAppBar: showAppBar);
    } catch (_) {
      final service = context.read<PairManagementService>();

      return BlocProvider(
        create: (_) => PairedReceiversBloc(service)
          ..add(const PairedReceiversLoadEvent()),
        child: PairedReceiversBody(showAppBar: showAppBar),
      );
    }
  }
}
