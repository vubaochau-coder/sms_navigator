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

    return BlocBuilder<OtpListBloc, OtpListState>(
      buildWhen: (previous, current) =>
          previous.selectedDate != current.selectedDate ||
          previous.items.length != current.items.length ||
          previous.isGroupingByDevice != current.isGroupingByDevice,
      builder: (context, state) {
        final dateDisplay = DateTimeUtils.formatDate(state.selectedDate);
        final dateLabel = l10n != null
            ? l10n.otpFilterDateWithCount(dateDisplay, state.items.length)
            : 'Ngày: $dateDisplay (${state.items.length} tin)';
        final groupLabel = l10n?.otpGroupByDevice ?? 'Nhóm theo máy';

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
              ),
              InkWell(
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
                    color: state.isGroupingByDevice
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isGroupingByDevice
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: state.isGroupingByDevice
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        groupLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: state.isGroupingByDevice
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
