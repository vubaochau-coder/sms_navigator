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
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: BlocBuilder<OtpListBloc, OtpListState>(
        buildWhen: (p, c) => p.directionFilter != c.directionFilter,
        builder: (context, state) {
          return Row(
            children: [
              _DirectionOption(
                label: l10n.smsFilterAll,
                isSelected: state.directionFilter == OtpDirectionFilter.all,
                onTap: () => _onSelect(context, OtpDirectionFilter.all),
              ),
              const SizedBox(width: 16),
              _DirectionOption(
                label: l10n.smsFilterSent,
                isSelected: state.directionFilter == OtpDirectionFilter.sent,
                onTap: () => _onSelect(context, OtpDirectionFilter.sent),
              ),
              const SizedBox(width: 16),
              _DirectionOption(
                label: l10n.smsFilterReceived,
                isSelected: state.directionFilter == OtpDirectionFilter.received,
                onTap: () => _onSelect(context, OtpDirectionFilter.received),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSelect(BuildContext context, OtpDirectionFilter filter) {
    BlocProvider.of<OtpListBloc>(context).add(
      OtpListChangeDirectionFilterEvent(filter),
    );
  }
}

class _DirectionOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DirectionOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor =
        isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: contentColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
