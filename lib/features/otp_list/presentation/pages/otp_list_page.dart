import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/ui_utils.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';
import '../widgets/otp_calendar_card.dart';
import '../widgets/otp_content_view.dart';

/// Màn hình xem danh sách OTP theo ngày — Thuần Stateless với BLoC.
class OtpListPage extends StatelessWidget {
  const OtpListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpListBloc(
        repository: DependencyContainer.instance.otpListRepository,
      )..add(OtpListLoadEvent(date: DateTime.now())),
      child: const _OtpListView(),
    );
  }
}

class _OtpListView extends StatelessWidget {
  const _OtpListView();

  void _copyToClipboard(BuildContext context, String text, String label) {
    HapticFeedback.lightImpact();
    UiUtils.copyToClipboard(
      context,
      text,
      successMessage: 'Đã sao chép $label: $text',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
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
      ),
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

          return Column(
            children: [
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
                      ? const Center(child: CircularProgressIndicator())
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
          );
        },
      ),
    );
  }
}
