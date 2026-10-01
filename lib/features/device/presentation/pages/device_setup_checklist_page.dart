import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/repositories/device_setup_repository.dart';
import '../bloc/device_setup_bloc.dart';
import '../bloc/device_setup_event.dart';
import '../bloc/device_setup_state.dart';

class DeviceSetupChecklistPage extends StatelessWidget {
  const DeviceSetupChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DeviceSetupBloc(repository: context.read<DeviceSetupRepository>())
            ..add(const DeviceSetupStarted()),
      child: const _DeviceSetupView(),
    );
  }
}

class _DeviceSetupView extends StatefulWidget {
  const _DeviceSetupView();

  @override
  State<_DeviceSetupView> createState() => _DeviceSetupViewState();
}

class _DeviceSetupViewState extends State<_DeviceSetupView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DeviceSetupBloc>().add(const DeviceSetupStarted());
    }
  }

  String get _oemDisplayName {
    final bloc = context.read<DeviceSetupBloc>();
    switch (bloc.state.oemName) {
      case 'xiaomi':
        return 'Xiaomi / HyperOS / MIUI';
      case 'oppo':
        return 'Oppo / Realme / OnePlus (ColorOS)';
      case 'vivo':
        return 'Vivo / iQOO (FuntouchOS)';
      case 'huawei':
        return 'Huawei / Honor (EMUI / HarmonyOS)';
      case 'samsung':
        return 'Samsung (One UI)';
      default:
        return 'thiết bị của bạn';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceSetupTitle)),
      body: BlocBuilder<DeviceSetupBloc, DeviceSetupState>(
        builder: (context, state) {
          if (state.isLoading &&
              state.smsPermissionGranted == null &&
              state.batteryUnrestricted == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: Dimens.screenPadding,
            children: [
              Text(
                l10n.deviceSetupGuide,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _SetupStepCard(
                icon: Icons.sms_rounded,
                title: l10n.stepSmsPermissionTitle,
                subtitle: l10n.stepRequiredForSender,
                status: _statusLabel(context, state.smsPermissionGranted),
                isDone: state.smsPermissionGranted == true,
                actionLabel: state.smsPermissionPermanentlyDenied
                    ? l10n.openAppDetailsAction
                    : l10n.grantPermissionStepAction,
                onAction: () {
                  context.read<DeviceSetupBloc>().add(
                    state.smsPermissionPermanentlyDenied
                        ? const DeviceSetupAppSettingsOpened()
                        : const DeviceSetupSmsPermissionRequested(),
                  );
                },
              ),
              _SetupStepCard(
                icon: Icons.battery_saver_rounded,
                title: l10n.stepBatteryOptimizationTitle,
                subtitle: l10n.stepRequiredForSender,
                status: _statusLabel(context, state.batteryUnrestricted),
                isDone: state.batteryUnrestricted == true,
                actionLabel: l10n.requestBatteryOptimizationAction,
                onAction: () {
                  context.read<DeviceSetupBloc>().add(
                    const DeviceSetupBatteryOptimizationRequested(),
                  );
                },
              ),
              _SetupStepCard(
                icon: Icons.restart_alt_rounded,
                title: state.isAggressiveRom
                    ? l10n.stepAutostartTitle(_oemDisplayName)
                    : l10n.stepBackgroundTitle,
                subtitle: l10n.stepRequiredForSender,
                status: state.autostartAcknowledged
                    ? l10n.statusCompleted
                    : (state.autostartScreenOpened
                        ? l10n.statusPendingConfirm
                        : l10n.statusNotDone),
                isDone: state.autostartAcknowledged,
                actionLabel: state.isAggressiveRom
                    ? l10n.openAutostartAction
                    : l10n.openBackgroundAction,
                doneActionLabel: l10n.reopenSettingsAction,
                onAction: () {
                  context.read<DeviceSetupBloc>().add(
                    const DeviceSetupAutostartSettingsOpened(),
                  );
                },
                secondaryActionLabel: state.autostartScreenOpened &&
                        !state.autostartAcknowledged
                    ? l10n.iHaveEnabledAction
                    : null,
                onSecondaryAction: () {
                  context.read<DeviceSetupBloc>().add(
                    const DeviceSetupAutostartAcknowledged(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(BuildContext context, bool? status) {
    if (status == null) return context.l10n.statusChecking;
    return status ? context.l10n.statusCompleted : context.l10n.statusNotDone;
  }
}

class _SetupStepCard extends StatelessWidget {
  const _SetupStepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.isDone,
    required this.actionLabel,
    required this.onAction,
    this.doneActionLabel,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final bool? isDone;
  final String? actionLabel;
  final String? doneActionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doneColor = Colors.green.shade700;
    final pendingColor = Colors.orange.shade800;
    final statusColor =
        isDone == true ? doneColor : (isDone == null ? colorScheme.onSurfaceVariant : pendingColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone == true
              ? Colors.green.shade300
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isDone == true
                    ? Icons.check_circle_rounded
                    : (isDone == null
                        ? Icons.info_outline_rounded
                        : Icons.radio_button_unchecked_rounded),
                size: 22,
                color: isDone == true
                    ? doneColor
                    : (isDone == null
                        ? colorScheme.onSurfaceVariant
                        : pendingColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              if (secondaryActionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      secondaryActionLabel!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              if (actionLabel != null && isDone != true)
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
                ),
              if (doneActionLabel != null && isDone == true)
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    doneActionLabel!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
