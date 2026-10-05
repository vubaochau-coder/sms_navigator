import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/bottom_sheet_utils.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../settings/whitelist_settings_page.dart';
import '../bloc/device_profile_cubit.dart';
import '../bloc/device_profile_state.dart';
import '../bloc/device_setup_bloc.dart';
import '../bloc/device_setup_event.dart';
import '../bloc/device_setup_state.dart';
import '../device_setup_checklist_page.dart';

class DeviceProfileBottomSheet extends StatelessWidget {
  const DeviceProfileBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final setupBloc = context.read<DeviceSetupBloc>();
    return BottomSheetUtils.showBaseForm(
      context: context,
      child: BlocProvider.value(
        value: setupBloc,
        child: const DeviceProfileBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Card thông tin thiết bị (Tên + ID + Sửa tên)
          _buildDeviceInfoCard(context, colorScheme),
          const SizedBox(height: 16),

          // 2. Tình trạng hoạt động (Quyền SMS + Chạy nền + Shortcut kiểm tra)
          _buildHealthSection(context, colorScheme),
          const SizedBox(height: 16),

          // 3. Tùy chọn giao diện & Bộ lọc
          _buildPreferencesSection(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context, ColorScheme colorScheme) {
    return BlocBuilder<DeviceProfileCubit, DeviceProfileState>(
      builder: (context, state) {
        final deviceId = state.deviceId;
        final displayId = deviceId.length > 20
            ? '${deviceId.substring(0, 8)}...${deviceId.substring(deviceId.length - 6)}'
            : (deviceId.isEmpty ? 'Chưa xác định' : deviceId);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.deviceName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: context.l10n.channelRenameDeviceTooltip,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _onEditDeviceName(context, state.deviceName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: deviceId.isNotEmpty
                          ? () => ToastUtils.copyToClipboard(
                                deviceId,
                                successMessage: 'Đã sao chép ID thiết bị',
                              )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: $displayId',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (deviceId.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthSection(BuildContext context, ColorScheme colorScheme) {
    return BlocBuilder<DeviceSetupBloc, DeviceSetupState>(
      builder: (context, state) {
        final smsGranted = state.smsPermissionGranted == true;
        final batteryOk = state.batteryUnrestricted == true;
        final allOk = state.isAllCriticalStepsDone;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TÌNH TRẠNG THIẾT BỊ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: allOk
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          allOk ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 13,
                          color: allOk ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          allOk ? 'Sẵn sàng' : 'Cần chú ý',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: allOk ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildStatusRow(
                      context,
                      isOk: smsGranted,
                      title: 'Quyền đọc SMS',
                      statusText: smsGranted ? 'Đã cấp quyền' : 'Chưa cấp quyền',
                      action: !smsGranted
                          ? TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () {
                                context
                                    .read<DeviceSetupBloc>()
                                    .add(const DeviceSetupSmsPermissionRequested());
                              },
                              child: const Text('Cấp ngay'),
                            )
                          : null,
                    ),
                    Divider(
                      height: 16,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    _buildStatusRow(
                      context,
                      isOk: batteryOk,
                      title: 'Chạy ngầm & Tối ưu pin',
                      statusText: batteryOk
                          ? 'Đã tắt hạn chế pin'
                          : 'Có thể bị hệ điều hành tắt',
                    ),
                    Divider(
                      height: 16,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DeviceSetupChecklistPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chi tiết thiết lập thiết bị & cài đặt OEM',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required bool isOk,
    required String title,
    required String statusText,
    Widget? action,
  }) {
    final color = isOk ? AppColors.success : AppColors.warning;
    return Row(
      children: [
        Icon(
          isOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, ColorScheme colorScheme) {
    final currentTheme = context.watch<ThemeCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'CÀI ĐẶT & TÙY CHỌN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          color: colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Chế độ hiển thị',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Hệ thống', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.brightness_auto_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Sáng', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.light_mode_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Tối', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                        ),
                      ],
                      selected: {currentTheme},
                      onSelectionChanged: (selected) {
                        context.read<ThemeCubit>().setThemeMode(selected.first);
                      },
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(
                  Icons.filter_list_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text(
                  'Bộ lọc SMS (Whitelist)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Cấu hình danh sách số điện thoại/OTP cho phép',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WhitelistSettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onEditDeviceName(BuildContext context, String currentName) async {
    final l10n = context.l10n;
    final newName = await DialogUtils.showInputDialog(
      context: context,
      title: l10n.channelRenameDialogTitle,
      labelText: l10n.channelDeviceNameLabel,
      hintText: l10n.channelDeviceNameHint,
      initialValue: currentName,
      maxLength: 128,
      icon: Icons.edit_rounded,
      confirmText: l10n.channelSaveConfirm,
      cancelText: l10n.cancel,
    );
    if (newName != null && newName.trim().isNotEmpty && context.mounted) {
      await context.read<DeviceProfileCubit>().renameDevice(newName);
    }
  }
}
