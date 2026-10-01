import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../sender/data/models/whitelist_config_model.dart';
import '../../data/repositories/whitelist_repository.dart';
import '../bloc/whitelist_bloc.dart';
import '../bloc/whitelist_event.dart';
import '../bloc/whitelist_state.dart';
import '../widgets/whitelist_add_entry_dialog.dart';

/// Màn cấu hình Danh sách trắng SMS (deny-by-default).
class WhitelistSettingsPage extends StatelessWidget {
  const WhitelistSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => WhitelistBloc(
        repository: ctx.read<WhitelistRepository>(),
      )..add(const WhitelistStarted()),
      child: const _WhitelistSettingsView(),
    );
  }
}

class _WhitelistSettingsView extends StatelessWidget {
  const _WhitelistSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.whitelistSettingsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addWhitelistDialogTitle),
      ),
      body: BlocConsumer<WhitelistBloc, WhitelistState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.config.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.blocksEverything) const _BlockedBanner(),
              const _AllAddressesTile(),
              const _SectionCaption(),
              const Expanded(child: _EntriesSection()),
            ],
          );
        },
      ),
    );
  }
}

class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whitelistEmptyWarningTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.whitelistEmptyWarningMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllAddressesTile extends StatelessWidget {
  const _AllAddressesTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<WhitelistBloc, WhitelistState>(
      buildWhen: (p, c) => p.config.mode != c.config.mode,
      builder: (context, state) {
        final isAllAddresses = state.config.mode == WhitelistMode.allAddresses;
        return SwitchListTile(
          value: isAllAddresses,
          title: Text(l10n.whitelistAllAddressesToggle),
          subtitle: Text(l10n.whitelistAllAddressesDesc),
          onChanged: (value) {
            context.read<WhitelistBloc>().add(
                  WhitelistModeChanged(
                    isAllAddresses
                        ? WhitelistMode.explicit
                        : WhitelistMode.allAddresses,
                  ),
                );
          },
        );
      },
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    return BlocBuilder<WhitelistBloc, WhitelistState>(
      buildWhen: (p, c) => p.config.mode != c.config.mode,
      builder: (context, state) {
        final caption = state.config.mode == WhitelistMode.allAddresses
            ? l10n.whitelistOtpSectionCaption
            : l10n.whitelistExplicitDesc;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

class _EntriesSection extends StatelessWidget {
  const _EntriesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    return BlocBuilder<WhitelistBloc, WhitelistState>(
      buildWhen: (p, c) => p.config.entries != c.config.entries,
      builder: (context, state) {
        if (state.config.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block_rounded, size: 48, color: colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  l10n.whitelistEmptyListHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: state.config.entries.length,
          itemBuilder: (context, index) =>
              _WhitelistEntryTile(entry: state.config.entries[index]),
        );
      },
    );
  }
}

class _WhitelistEntryTile extends StatelessWidget {
  const _WhitelistEntryTile({required this.entry});

  final WhitelistEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    return ListTile(
      leading: Icon(
        entry.allowOtp
            ? Icons.enhanced_encryption_rounded
            : Icons.sms_rounded,
        color: entry.allowOtp
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      title: Text(entry.address),
      subtitle: Text(
        entry.allowOtp ? l10n.allowSendingOtp : l10n.addWhitelistHint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: entry.allowOtp
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: l10n.allowSendingOtp,
            child: Checkbox(
              value: entry.allowOtp,
              onChanged: (_) => context
                  .read<WhitelistBloc>()
                  .add(WhitelistAllowOtpToggled(entry)),
            ),
          ),
          IconButton(
            tooltip: l10n.whitelistRemoveAction,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => context
                .read<WhitelistBloc>()
                .add(WhitelistEntryRemoved(entry)),
          ),
        ],
      ),
    );
  }
}

void _showAddDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<WhitelistBloc>(),
      child: const WhitelistAddEntryDialog(),
    ),
  );
}
