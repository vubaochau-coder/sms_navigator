import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/models/decrypted_otp_item.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';
import 'otp_record_card.dart';

/// View nội dung danh sách OTP kết nối OtpListBloc (RefreshIndicator, Shimmer).
class OtpContentView extends StatelessWidget {
  const OtpContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<OtpListBloc>(context).add(
          const OtpListLoadEvent(),
        );
      },
      child: BlocBuilder<OtpListBloc, OtpListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const ShimmerLoadingList();
          }

          return _ContentView(
            items: state.filteredItems,
            groupedByDevice: state.filteredGroupedByDevice,
            isGroupingByDevice: state.isGroupingByDevice,
            dateDisplay: DateTimeUtils.formatDate(state.selectedDate),
          );
        },
      ),
    );
  }
}

/// View thuần túy hiển thị danh sách OTP (dạng phẳng, gom nhóm hoặc empty).
class _ContentView extends StatelessWidget {
  const _ContentView({
    required this.items,
    required this.groupedByDevice,
    required this.isGroupingByDevice,
    required this.dateDisplay,
  });

  final List<DecryptedOtpItem> items;
  final Map<String, List<DecryptedOtpItem>> groupedByDevice;
  final bool isGroupingByDevice;
  final String dateDisplay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return _buildEmptyState(context, colorScheme);
    }

    if (isGroupingByDevice) {
      return _buildGroupedList(context, colorScheme);
    }

    return _buildFlatList(context);
  }

  Widget _buildFlatList(BuildContext context) {
    return ListView.builder(
      padding: Dimens.screenPadding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return OtpRecordCard(item: item);
      },
    );
  }

  Widget _buildGroupedList(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: Dimens.screenPadding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: groupedByDevice.entries.map((entry) {
        final deviceName = entry.key;
        final list = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${list.length} tin',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...list.map(
              (item) => OtpRecordCard(item: item),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    final l10n = context.l10n;
    final emptyTitle = l10n.otpEmptyInDate(dateDisplay);
    final emptyGuide = l10n.otpEmptyGuide;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyGuide,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
