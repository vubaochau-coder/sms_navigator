import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../bloc/device_setup_bloc.dart';
import '../bloc/device_setup_event.dart';
import '../pages/device_setup_checklist_page.dart';

Future<void> showSmsPermissionPromptDialog(
  BuildContext context, {
  bool permanentlyDenied = false,
}) {
  final l10n = context.l10n;

  return DialogUtils.showBaseForm<void>(
    context: context,
    barrierDismissible: true,
    AlertDialog(
      title: Text(l10n.permissionDialogTitle),
      content: Text(
        l10n.permissionDialogMessage,
        style: const TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            BlocProvider.of<DeviceSetupBloc>(context).add(
              const DeviceSetupDontPromptDismissed(),
            );
          },
          child: Text(l10n.dontRemindAgain),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DeviceSetupChecklistPage(),
              ),
            );
          },
          child: Text(l10n.goToSettings),
        ),
      ],
    ),
  );
}
