import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';

/// Cụm chọn hướng SMS hiển thị: Tất cả - SMS Gửi Đi - SMS Nhận Được.
class OtpDirectionFilterBar extends StatelessWidget {
  const OtpDirectionFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: BlocBuilder<OtpListBloc, OtpListState>(
        buildWhen: (previous, current) =>
            previous.directionFilter != current.directionFilter,
        builder: (context, state) {
          return SegmentedButton<OtpDirectionFilter>(
            segments: [
              ButtonSegment(
                value: OtpDirectionFilter.all,
                label: Text(l10n.smsFilterAll),
              ),
              ButtonSegment(
                value: OtpDirectionFilter.sent,
                label: Text(l10n.smsFilterSent),
              ),
              ButtonSegment(
                value: OtpDirectionFilter.received,
                label: Text(l10n.smsFilterReceived),
              ),
            ],
            selected: {state.directionFilter},
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest;
              }),
            ),
            onSelectionChanged: (selection) {
              BlocProvider.of<OtpListBloc>(context).add(
                OtpListChangeDirectionFilterEvent(selection.first),
              );
            },
          );
        },
      ),
    );
  }
}
