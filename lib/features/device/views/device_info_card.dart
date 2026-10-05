import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../bloc/device_profile_cubit.dart';
import '../bloc/device_profile_state.dart';

/// Card thông tin thiết bị: hiển thị biểu tượng, tên thiết bị, nút sửa tên và Device ID.
class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
