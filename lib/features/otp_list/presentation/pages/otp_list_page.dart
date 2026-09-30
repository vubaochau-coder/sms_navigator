import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';
import '../widgets/otp_calendar_card.dart';
import '../widgets/otp_content_view.dart';

/// Màn hình xem danh sách OTP theo ngày — Thuần Stateless với BLoC.
class OtpListPage extends StatelessWidget {
  const OtpListPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpListBloc(
        repository: DependencyContainer.instance.otpListRepository,
      )..add(OtpListLoadEvent(date: DateTime.now())),
      child: _OtpListView(showAppBar: showAppBar),
    );
  }
}

class _OtpListView extends StatelessWidget {
  const _OtpListView({required this.showAppBar});

  final bool showAppBar;

  void _copyToClipboard(BuildContext context, String text, String label) {
    HapticFeedback.lightImpact();
    UiUtils.copyToClipboard(text, successMessage: 'Đã sao chép $label: $text');
  }

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

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Danh Sách OTP'),
              actions: [
                BlocBuilder<OtpListBloc, OtpListState>(
                  builder: (context, state) {
                    return IconButton(
                      icon: Icon(
                        state.isGroupingByDevice
                            ? Icons.view_agenda_rounded
                            : Icons.group_work_rounded,
                      ),
                      tooltip: state.isGroupingByDevice
                          ? 'Xem dạng danh sách phẳng'
                          : 'Gom nhóm theo thiết bị gửi',
                      onPressed: () {
                        context.read<OtpListBloc>().add(
                          const OtpListToggleGroupEvent(),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Làm mới',
                  onPressed: () {
                    final selectedDate = context
                        .read<OtpListBloc>()
                        .state
                        .selectedDate;
                    context.read<OtpListBloc>().add(
                      OtpListLoadEvent(date: selectedDate),
                    );
                  },
                ),
              ],
            )
          : null,
      body: BlocConsumer<OtpListBloc, OtpListState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final dateDisplay = DateTimeUtils.formatDate(state.selectedDate);
          final isToday = DateTimeUtils.isSameDay(
            state.selectedDate,
            DateTime.now(),
          );
          final l10n = AppLocalizations.of(context);
          final dateDayMonth = DateTimeUtils.formatDate(state.selectedDate, pattern: 'dd/MM');
          final headerDateText = isToday
              ? (l10n != null ? l10n.otpTodayWithDate(dateDayMonth) : 'Hôm nay, $dateDayMonth')
              : dateDisplay;

          return SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
              if (!showAppBar)
                _OtpCompactHeader(
                  dateText: headerDateText,
                  onOpenSettings: () => _openServerSettings(context),
                ),
              OtpCalendarCard(
                focusedDay: state.focusedDate,
                selectedDay: state.selectedDate,
                calendarFormat: state.calendarFormat,
                onDaySelected: (selectedDay, focusedDay) {
                  context.read<OtpListBloc>().add(
                    OtpListSelectDateEvent(
                      selectedDay: selectedDay,
                      focusedDay: focusedDay,
                    ),
                  );
                },
                onFormatChanged: (format) {
                  context.read<OtpListBloc>().add(
                    OtpListChangeFormatEvent(format),
                  );
                },
                onPageChanged: (focusedDay) {
                  context.read<OtpListBloc>().add(
                    OtpListChangeFocusedDayEvent(focusedDay),
                  );
                },
              ),
              Padding(
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
                          'Ngày: $dateDisplay (${state.items.length} tin)',
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
                              'Nhóm theo máy',
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
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<OtpListBloc>().add(
                      OtpListLoadEvent(date: state.selectedDate),
                    );
                  },
                  child: state.isLoading
                      ? const ShimmerLoadingList()
                      : OtpContentView(
                          items: state.items,
                          groupedByDevice: state.groupedByDevice,
                          isGroupingByDevice: state.isGroupingByDevice,
                          dateDisplay: dateDisplay,
                          onCopyOtp: (text, label) =>
                              _copyToClipboard(context, text, label),
                        ),
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}

class _OtpCompactHeader extends StatelessWidget {
  const _OtpCompactHeader({
    required this.dateText,
    required this.onOpenSettings,
  });

  final String dateText;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDark = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness ==
                          Brightness.dark);
              return IconButton(
                icon: Icon(
                  isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                tooltip:
                    isDark ? 'Chuyển sang nền sáng' : 'Chuyển sang nền tối',
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsAction,
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }
}
