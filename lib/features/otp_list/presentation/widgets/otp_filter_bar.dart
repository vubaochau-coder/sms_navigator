import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';

/// Thanh bộ lọc và tuỳ chọn nhóm danh sách OTP.
class OtpFilterBar extends StatelessWidget {
  const OtpFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<OtpListBloc, OtpListState>(
            buildWhen: (p, c) {
              return p.selectedDate != c.selectedDate ||
                p.items.length != c.items.length;
            },
            builder: (context, state) {
              final dateDisplay = DateTimeUtils.formatDate(state.selectedDate);
              final dateLabel = l10n != null
                  ? l10n.otpFilterDateWithCount(dateDisplay, state.items.length)
                  : 'Ngày: $dateDisplay (${state.items.length} tin)';

              return Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              );
            },
          ),
          BlocBuilder<OtpListBloc, OtpListState>(
            buildWhen: (p, c) => p.isGroupingByDevice != c.isGroupingByDevice,
            builder: (context, state) {
              final groupLabel = l10n?.otpGroupByDevice ?? 'Nhóm theo máy';
              final isGrouping = state.isGroupingByDevice;

              return InkWell(
                onTap: () {
                  context.read<OtpListBloc>().add(
                        const OtpListToggleGroupEvent(),
                      );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isGrouping
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isGrouping
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: isGrouping
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        groupLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isGrouping
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
