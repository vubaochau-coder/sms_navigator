import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../device/presentation/pages/device_setup_checklist_page.dart';
import '../../../settings/presentation/pages/whitelist_settings_page.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_state.dart';

/// Header rút gọn cho trang danh sách OTP, hiển thị ngày hiện tại và nút đổi theme.
class OtpCompactHeader extends StatelessWidget {
  const OtpCompactHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;

    return BlocSelector<OtpListBloc, OtpListState, DateTime>(
      selector: (state) => state.selectedDate,
      builder: (context, selectedDate) {
        final isToday = DateTimeUtils.isSameDay(
          selectedDate,
          DateTime.now(),
        );
        final String dateText;
        if (isToday) {
          final dateDayMonth = DateTimeUtils.formatDate(
            selectedDate,
            pattern: 'dd/MM',
          );
          dateText = l10n.otpTodayWithDate(dateDayMonth);
        } else {
          dateText = DateTimeUtils.formatDate(selectedDate);
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
              IconButton(
                tooltip: l10n.whitelistSettingsTitle,
                icon: const Icon(Icons.fact_check_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WhitelistSettingsPage(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Thiết lập thiết bị',
                icon: const Icon(Icons.settings_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DeviceSetupChecklistPage(),
                    ),
                  );
                },
              ),
              const ThemeToggleButton(),
            ],
          ),
        );
      },
    );
  }
}
