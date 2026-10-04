import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../../../core/models/whitelist_config_model.dart';
import '../../../../core/repositories/whitelist_repository.dart';
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
        heroTag: 'whitelist_settings_add_fab',
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => BlocProvider.value(
              value: BlocProvider.of<WhitelistBloc>(context),
              child: const WhitelistAddEntryDialog(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addWhitelistDialogTitle),
      ),
      body: BlocBuilder<WhitelistBloc, WhitelistState>(
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
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
    return BlocSelector<WhitelistBloc, WhitelistState, WhitelistMode>(
      selector: (state) => state.config.mode,
      builder: (context, mode) {
        final isAllAddresses = mode == WhitelistMode.allAddresses;
        void toggle() {
          BlocProvider.of<WhitelistBloc>(context).add(
            WhitelistModeChanged(
              isAllAddresses
                  ? WhitelistMode.explicit
                  : WhitelistMode.allAddresses,
            ),
          );
        }

        return ListTile(
          title: Text(l10n.whitelistAllAddressesToggle),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.whitelistAllAddressesDesc),
          ),
          trailing: AppSwitch(
            value: isAllAddresses,
            onChanged: (_) {
              toggle();
            },
          ),
          onTap: toggle,
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
    return BlocSelector<WhitelistBloc, WhitelistState, WhitelistMode>(
      selector: (state) => state.config.mode,
      builder: (context, mode) {
        final caption = mode == WhitelistMode.allAddresses
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

    return BlocSelector<WhitelistBloc, WhitelistState, List<WhitelistEntryModel>>(
      selector: (state) => state.config.entries,
      builder: (context, entries) {
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 72),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.whitelistEmptyListHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return _WhitelistEntryTile(entry: entries[index]);
          },
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
              onChanged: (_) {
                BlocProvider.of<WhitelistBloc>(
                  context,
                ).add(WhitelistAllowOtpToggled(entry));
              },
            ),
          ),
          IconButton(
            tooltip: l10n.whitelistRemoveAction,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              BlocProvider.of<WhitelistBloc>(
                context,
              ).add(WhitelistEntryRemoved(entry));
            },
          ),
        ],
      ),
    );
  }
}
