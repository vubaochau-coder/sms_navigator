import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../bloc/sms_bloc.dart';
import 'sms_tile_view.dart';

export 'sms_tile_view.dart';

class MessageListView extends StatelessWidget {
  const MessageListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsBloc, SmsState>(
      // Chỉ dựng lại danh sách khi dữ liệu hiển thị đổi (không vì truncated / hasFetchedOnce).
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.messages != current.messages ||
          previous.selectedDate != current.selectedDate ||
          previous.cachedAt != current.cachedAt,
      builder: (context, state) {
        if (state.isLoading) {
          return const ShimmerLoadingList(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 96),
            itemSpacing: 8,
            cardHeight: 76,
          );
        }

        final Widget content;
        if (state.messages.isEmpty) {
          content = CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: SmsEmptyPane(date: state.selectedDate),
              ),
            ],
          );
        } else {
          content = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
            itemCount: state.messages.length,
            itemBuilder: (context, index) =>
                SmsTileView(message: state.messages[index]),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.cachedAt != null) SmsOfflineNotice(cachedAt: state.cachedAt!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                context.l10n.smsDailyMessageCount(state.messages.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<SmsBloc>().add(const SmsLoadDataEvent());
                },
                child: content,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Ngoại tuyến — đang xem bản lưu lúc …" (BACKLOG 1.7).
class SmsOfflineNotice extends StatelessWidget {
  const SmsOfflineNotice({super.key, required this.cachedAt});

  final DateTime cachedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 14, color: scheme.tertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.smsOfflineCached(DateTimeUtils.formatDateTime(cachedAt)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class SmsEmptyPane extends StatelessWidget {
  const SmsEmptyPane({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sms_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            context.l10n.smsEmptyInDate(DateTimeUtils.formatDate(date)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
