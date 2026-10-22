import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../bloc/activity_cubit.dart';
import '../bloc/activity_state.dart';

class ActivityFilterBar extends StatelessWidget {
  const ActivityFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = context.select((ActivityCubit cubit) => cubit.state.filter);
    final labels = {
      ActivityFilter.all: l10n.activityFilterAll,
      ActivityFilter.relay: l10n.activityFilterRelay,
      ActivityFilter.channels: l10n.activityFilterChannels,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected == entry.key,
                onSelected: (_) => context.read<ActivityCubit>().selectFilter(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}
