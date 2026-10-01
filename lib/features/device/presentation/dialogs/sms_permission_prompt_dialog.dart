import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/device_setup_bloc.dart';
import '../bloc/device_setup_event.dart';
import '../pages/device_setup_checklist_page.dart';

Future<void> showSmsPermissionPromptDialog(
  BuildContext context, {
  bool permanentlyDenied = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Thiết lập quyền'),
        content: const Text(
          'Một số quyền quan trọng chưa được cấp, ứng dụng có thể sẽ không hoạt động chính xác.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<DeviceSetupBloc>().add(
                const DeviceSetupDontPromptDismissed(),
              );
            },
            child: const Text('Không nhắc lại'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DeviceSetupChecklistPage(),
                ),
              );
            },
            child: const Text('Đi đến cài đặt'),
          ),
        ],
      );
    },
  );
}
