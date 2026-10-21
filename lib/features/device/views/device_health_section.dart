import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../bloc/device_setup_bloc.dart';
import '../bloc/device_setup_event.dart';
import '../bloc/device_setup_state.dart';
import '../device_setup_checklist_page.dart';
import '../../../core/extensions/context_extensions.dart';

/// Section hiển thị tình trạng thiết bị: Quyền đọc SMS, chạy ngầm & shortcut vào trang OEM checklist.
class DeviceHealthSection extends StatelessWidget {
  const DeviceHealthSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<DeviceSetupBloc, DeviceSetupState>(
      buildWhen: (previous, current) =>
          previous.smsPermissionGranted != current.smsPermissionGranted ||
          previous.batteryUnrestricted != current.batteryUnrestricted ||
          previous.isAllCriticalStepsDone != current.isAllCriticalStepsDone,
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
                    context.l10n.deviceHealthTitle,
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
                          allOk ? context.l10n.deviceHealthReady : context.l10n.deviceHealthNeedsAttention,
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
                    DeviceHealthStatusRow(
                      isOk: smsGranted,
                      title: context.l10n.deviceHealthSmsPermission,
                      statusText: smsGranted ? context.l10n.deviceHealthGranted : context.l10n.deviceHealthNotGranted,
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
                              child: Text(context.l10n.deviceHealthGrantNow),
                            )
                          : null,
                    ),
                    Divider(
                      height: 16,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    DeviceHealthStatusRow(
                      isOk: batteryOk,
                      title: context.l10n.deviceHealthBackground,
                      statusText: batteryOk
                          ? context.l10n.deviceHealthBatteryUnrestricted
                          : context.l10n.deviceHealthBatteryRestricted,
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
                                context.l10n.deviceHealthOemDetails,
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

}

/// Một dòng trạng thái (icon + tiêu đề + trạng thái + action tùy chọn).
class DeviceHealthStatusRow extends StatelessWidget {
  const DeviceHealthStatusRow({
    super.key,
    required this.isOk,
    required this.title,
    required this.statusText,
    this.action,
  });

  final bool isOk;
  final String title;
  final String statusText;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
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
}
