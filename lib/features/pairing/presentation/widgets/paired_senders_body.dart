import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../bloc/paired_senders_bloc.dart';
import '../bloc/paired_senders_event.dart';
import '../bloc/paired_senders_state.dart';
import '../pages/qr_scan_page.dart';
import 'paired_sender_card.dart';
import 'refreshable_empty_state.dart';

/// Widget thân danh sách thiết bị gửi OTP (Dành cho máy nhận).
class PairedSendersBody extends StatelessWidget {
  const PairedSendersBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: Dimens.screenPadding,
        child: BlocBuilder<PairedSendersBloc, PairedSendersState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const ShimmerLoadingList();
            }

            if (state.errorMessage != null) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: l10n.errorOccurred,
                message: state.errorMessage,
                actionLabel: l10n.retry,
                onAction: () => BlocProvider.of<PairedSendersBloc>(context)
                    .add(const PairedSendersLoadEvent()),
              );
            }

            if (state.devices.isEmpty) {
              return RefreshableEmptyState(
                onRefresh: () {
                  final completer = Completer<void>();
                  BlocProvider.of<PairedSendersBloc>(context).add(
                    PairedSendersLoadEvent(completer: completer),
                  );
                  return completer.future;
                },
                child: EmptyStateView(
                  icon: Icons.phonelink_ring_rounded,
                  title: l10n.emptySendersTitle,
                  message: l10n.emptySendersMessage,
                  actionLabel: l10n.scanSenderQrAction,
                  onAction: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrScanPage()),
                    );
                    if (context.mounted) {
                      BlocProvider.of<PairedSendersBloc>(context).add(
                        const PairedSendersLoadEvent(),
                      );
                    }
                  },
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () {
                final completer = Completer<void>();
                BlocProvider.of<PairedSendersBloc>(context).add(
                  PairedSendersLoadEvent(completer: completer),
                );
                return completer.future;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.devices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = state.devices[index];
                  return PairedSenderCard(item: item);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
