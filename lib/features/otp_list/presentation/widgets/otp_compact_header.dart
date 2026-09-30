import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_state.dart';

/// Header rút gọn cho trang danh sách OTP, hiển thị ngày hiện tại, nút đổi theme và cấu hình server.
class OtpCompactHeader extends StatelessWidget {
  const OtpCompactHeader({super.key});

  void _openServerSettings(BuildContext context) {
    final di = DependencyContainer.instance;
    showDialog(
      context: context,
      builder: (_) => ServerSettingsDialog(
        deviceStorageService: di.deviceStorageService,
        nativeRelayService: di.nativeRelayService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<OtpListBloc, OtpListState>(
      buildWhen: (previous, current) =>
          previous.selectedDate != current.selectedDate,
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
          dateText = l10n != null
              ? l10n.otpTodayWithDate(dateDayMonth)
              : 'Hôm nay, $dateDayMonth';
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
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n?.settingsAction ?? 'Cài đặt',
                onPressed: () => _openServerSettings(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
