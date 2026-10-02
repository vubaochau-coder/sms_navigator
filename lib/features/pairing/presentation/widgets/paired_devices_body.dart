import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../data/models/paired_device_item.dart';
import '../bloc/paired_receivers_bloc.dart';
import '../bloc/paired_receivers_event.dart';
import '../bloc/paired_receivers_state.dart';
import '../bloc/paired_senders_bloc.dart';
import '../bloc/paired_senders_event.dart';
import '../bloc/paired_senders_state.dart';
import '../pages/pairing_sender_page.dart';
import '../pages/pairing_qr_scan_page.dart';
import 'paired_receiver_card.dart';
import 'paired_sender_card.dart';

/// Thân danh sách thiết bị ghép đôi, dùng chung cho cả tab Máy nhận và
/// Máy gửi. Khác biệt giữa 2 tab được cấu hình qua tham số (bloc, card,
/// empty state và hành động khi danh sách rỗng).
class PairedDevicesBody<B extends Bloc<E, S>, E, S> extends StatelessWidget {
  const PairedDevicesBody({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.devices,
    required this.loadEvent,
    required this.cardBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyActionLabel,
    required this.onEmptyAction,
  });

  final bool Function(S state) isLoading;
  final String? Function(S state) errorMessage;
  final List<PairedDeviceItem> Function(S state) devices;
  final E Function(Completer<void>? completer) loadEvent;
  final Widget Function(PairedDeviceItem item) cardBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String emptyActionLabel;
  final Future<void> Function(BuildContext context) onEmptyAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: Dimens.screenPadding,
        child: BlocBuilder<B, S>(
          builder: (context, state) {
            if (isLoading(state)) {
              return const ShimmerLoadingList();
            }

            final error = errorMessage(state);
            if (error != null) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: context.l10n.errorOccurred,
                message: error,
                actionLabel: context.l10n.retry,
                onAction: () {
                  BlocProvider.of<B>(context).add(loadEvent(null));
                },
              );
            }

            final items = devices(state);
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _load(context),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 56),
                        child: EmptyStateView(
                          icon: emptyIcon,
                          title: emptyTitle,
                          message: emptyMessage,
                          actionLabel: emptyActionLabel,
                          onAction: () => onEmptyAction(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _load(context),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) => cardBuilder(items[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _load(BuildContext context) {
    final completer = Completer<void>();
    BlocProvider.of<B>(context).add(loadEvent(completer));
    return completer.future;
  }
}

/// Thân danh sách thiết bị nhận OTP (Dành cho máy gửi).
class PairedReceiversBody extends StatelessWidget {
  const PairedReceiversBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PairedDevicesBody<PairedReceiversBloc, PairedReceiversEvent,
        PairedReceiversState>(
      isLoading: (state) => state.isLoading,
      errorMessage: (state) => state.errorMessage,
      devices: (state) => state.devices,
      loadEvent: (completer) => PairedReceiversLoadEvent(completer: completer),
      cardBuilder: (item) => PairedReceiverCard(item: item),
      emptyIcon: Icons.phonelink_erase_rounded,
      emptyTitle: l10n.emptyReceiversTitle,
      emptyMessage: l10n.emptyReceiversMessage,
      emptyActionLabel: l10n.pairingGenerateQr,
      onEmptyAction: (context) async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const PairingSenderPage()),
        );
        if (changed == true && context.mounted) {
          BlocProvider.of<PairedReceiversBloc>(
            context,
          ).add(const PairedReceiversLoadEvent());
        }
      },
    );
  }
}

/// Thân danh sách thiết bị gửi OTP (Dành cho máy nhận).
class PairedSendersBody extends StatelessWidget {
  const PairedSendersBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PairedDevicesBody<PairedSendersBloc, PairedSendersEvent,
        PairedSendersState>(
      isLoading: (state) => state.isLoading,
      errorMessage: (state) => state.errorMessage,
      devices: (state) => state.devices,
      loadEvent: (completer) => PairedSendersLoadEvent(completer: completer),
      cardBuilder: (item) => PairedSenderCard(item: item),
      emptyIcon: Icons.phonelink_ring_rounded,
      emptyTitle: l10n.emptySendersTitle,
      emptyMessage: l10n.emptySendersMessage,
      emptyActionLabel: l10n.scanSenderQrAction,
      onEmptyAction: (context) async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PairingQrScanPage()),
        );
        if (context.mounted) {
          BlocProvider.of<PairedSendersBloc>(context).add(const PairedSendersLoadEvent());
        }
      },
    );
  }
}
