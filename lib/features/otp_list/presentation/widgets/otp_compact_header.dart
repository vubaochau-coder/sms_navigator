import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_state.dart';

/// Header rút gọn cho trang danh sách OTP, hiển thị ngày hiện tại và nút đổi theme.
class OtpCompactHeader extends StatelessWidget {
  const OtpCompactHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;

    return BlocBuilder<OtpListBloc, OtpListState>(
      buildWhen: (p, c) => p.selectedDate != c.selectedDate,
      builder: (context, state) {
        final isToday = DateTimeUtils.isSameDay(
          state.selectedDate,
          DateTime.now(),
        );
        final String dateText;
        if (isToday) {
          final dateDayMonth = DateTimeUtils.formatDate(
            state.selectedDate,
            pattern: 'dd/MM',
          );
          dateText = l10n.otpTodayWithDate(dateDayMonth);
        } else {
          dateText = DateTimeUtils.formatDate(state.selectedDate);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              Icon(Icons.sms_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const ThemeToggleButton(),
            ],
          ),
        );
      },
    );
  }
}
