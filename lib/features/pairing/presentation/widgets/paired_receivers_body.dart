import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../bloc/paired_receivers_bloc.dart';
import '../bloc/paired_receivers_event.dart';
import '../bloc/paired_receivers_state.dart';
import '../pages/pairing_sender_page.dart';
import 'paired_receiver_card.dart';
import 'refreshable_empty_state.dart';

/// Widget thân danh sách thiết bị nhận OTP (Dành cho máy gửi).
class PairedReceiversBody extends StatelessWidget {
  const PairedReceiversBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: Dimens.screenPadding,
        child: BlocBuilder<PairedReceiversBloc, PairedReceiversState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const ShimmerLoadingList();
            }

            if (state.errorMessage != null) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: context.l10n.errorOccurred,
                message: state.errorMessage,
                actionLabel: context.l10n.retry,
                onAction: () => BlocProvider.of<PairedReceiversBloc>(context)
                    .add(const PairedReceiversLoadEvent()),
              );
            }

            if (state.devices.isEmpty) {
              return RefreshableEmptyState(
                onRefresh: () {
                  final completer = Completer<void>();
                  BlocProvider.of<PairedReceiversBloc>(context).add(
                    PairedReceiversLoadEvent(completer: completer),
                  );
                  return completer.future;
                },
                child: EmptyStateView(
                  icon: Icons.phonelink_erase_rounded,
                  title: context.l10n.emptyReceiversTitle,
                  message: context.l10n.emptyReceiversMessage,
                  actionLabel: context.l10n.pairingGenerateQr,
                  onAction: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const PairingSenderPage(),
                      ),
                    );
                    if (changed == true && context.mounted) {
                      BlocProvider.of<PairedReceiversBloc>(context).add(
                        const PairedReceiversLoadEvent(),
                      );
                    }
                  },
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () {
                final completer = Completer<void>();
                BlocProvider.of<PairedReceiversBloc>(context).add(
                  PairedReceiversLoadEvent(completer: completer),
                );
                return completer.future;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.devices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = state.devices[index];
                  return PairedReceiverCard(item: item);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
