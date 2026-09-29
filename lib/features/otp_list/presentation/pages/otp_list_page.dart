import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../domain/models/decrypted_otp_item.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';

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

class _OtpListView extends StatefulWidget {
  const _OtpListView();

  @override
  State<_OtpListView> createState() => _OtpListViewState();
}

class _OtpListViewState extends State<_OtpListView> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      context.read<OtpListBloc>().add(OtpListLoadEvent(date: selectedDay));
    }
  }

  void _copyToClipboard(String text, String label) {
    HapticFeedback.lightImpact();
    UiUtils.copyToClipboard(
      context,
      text,
      successMessage: 'Đã sao chép $label: $text',
    );
  }

  void _showFullMessageDialog(DecryptedOtpItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateTimeUtils.formatDateTime(item.receivedAt, includeSeconds: true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sms_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.sender,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Meta info
              Row(
                children: [
                  Icon(Icons.phone_android_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    item.senderDeviceName,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // OTP Highlight
              if (item.otp != 'SMS' && item.otp != '******') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MÃ XÁC THỰC (OTP)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            item.otp,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AppColors.success,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Sao chép'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        onPressed: () => _copyToClipboard(item.otp, 'mã OTP'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Nội dung tin nhắn gốc:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: SelectableText(
                  item.fullMessage.isNotEmpty ? item.fullMessage : '[Không có nội dung]',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: const Text('Sao chép toàn bộ tin nhắn'),
                      onPressed: () => _copyToClipboard(item.fullMessage, 'toàn bộ tin nhắn'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateDisplay = DateTimeUtils.formatDate(_selectedDay);

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
                  context.read<OtpListBloc>().add(const OtpListToggleGroupEvent());
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () {
              context.read<OtpListBloc>().add(OtpListLoadEvent(date: _selectedDay));
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
          return Column(
            children: [
              // Calendar Filter Bar (Customizable with app theme)
              _buildCalendarCard(colorScheme),
              // Filter info banner & Group toggle badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.primary),
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
                        context.read<OtpListBloc>().add(const OtpListToggleGroupEvent());
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              // Body Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<OtpListBloc>().add(OtpListLoadEvent(date: _selectedDay));
                  },
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.items.isEmpty
                          ? _buildEmptyState(colorScheme, dateDisplay)
                          : state.isGroupingByDevice
                              ? _buildGroupedList(state.groupedByDevice, colorScheme)
                              : _buildFlatList(state.items, colorScheme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Bộ lọc Date Picker bằng TableCalendar — Tuỳ biến sâu theo Soft Modern Theme.
  Widget _buildCalendarCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withAlpha(80)),
          ),
          formatButtonTextStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          titleTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: colorScheme.primary),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
          todayDecoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary),
          ),
          todayTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          defaultTextStyle: TextStyle(color: colorScheme.onSurface),
          weekendTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  /// Danh sách dạng phẳng xếp theo thời gian mới nhất lên đầu.
  Widget _buildFlatList(List<DecryptedOtpItem> items, ColorScheme colorScheme) {
    return ListView.builder(
      padding: Dimens.screenPadding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildOtpCard(item, colorScheme);
      },
    );
  }

  /// Danh sách gom nhóm theo thiết bị gửi.
  Widget _buildGroupedList(
    Map<String, List<DecryptedOtpItem>> groups,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: Dimens.screenPadding,
      children: groups.entries.map((entry) {
        final deviceName = entry.key;
        final list = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
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
                      Icon(Icons.phone_android_rounded, size: 16, color: colorScheme.primary),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            ...list.map((item) => _buildOtpCard(item, colorScheme)),
          ],
        );
      }).toList(),
    );
  }

  /// Card hiển thị chi tiết mã OTP / SMS.
  Widget _buildOtpCard(DecryptedOtpItem item, ColorScheme colorScheme) {
    final timeStr = DateTimeUtils.formatTime(item.receivedAt, includeSeconds: true);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Sender & Time & Device
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.sender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.phone_android_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    item.senderDeviceName,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: OTP Value & Copy Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item.otp == 'SMS' ? 'THÔNG BÁO SMS' : item.otp,
                    style: TextStyle(
                      fontSize: item.otp == 'SMS' ? 14 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: item.otp == 'SMS' ? 0.5 : 2.0,
                      fontFamily: item.otp == 'SMS' ? null : 'monospace',
                      color: item.otp == 'SMS' ? colorScheme.secondary : AppColors.success,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (item.otp != 'SMS' && item.otp != '******')
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Sao chép mã', style: TextStyle(fontSize: 11)),
                      onPressed: () => _copyToClipboard(item.otp, 'mã OTP'),
                    ),
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    tooltip: 'Xem toàn bộ tin nhắn',
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                    ),
                    onPressed: () => _showFullMessageDialog(item),
                  ),
                ],
              ),
            ],
          ),
          if (item.fullMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.fullMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Trạng thái rỗng khi không có OTP trong ngày đã chọn.
  Widget _buildEmptyState(ColorScheme colorScheme, String dateDisplay) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
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
              'Không có mã OTP nào trong ngày $dateDisplay',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các tin nhắn OTP hoặc SMS được relay trong ngày này sẽ xuất hiện tại đây. Bạn có thể chọn ngày khác trên thanh lịch phía trên.',
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
