import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/relay_log_entry.dart';
import '../../../core/models/relay_sms_activity.dart';
import '../../../core/utils/date_time_utils.dart';

/// Một SMS trên tab Hoạt động: một dòng duy nhất cho mọi kênh, trạng thái
/// "Đang gửi" được thay bằng kết quả cuối khi các kênh gửi xong.
class RelaySmsTile extends StatelessWidget {
  const RelaySmsTile({super.key, required this.activity});

  final RelaySmsActivity activity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;
    final at = activity.at;
    final formattedTime = at != null ? DateTimeUtils.formatDate(at, pattern: 'HH:mm:ss · dd/MM/yyyy') : '';
    final targets = activity.targets;

    final (Color color, IconData icon, String label) = switch (activity.outcome) {
      RelaySmsOutcome.sending => (Colors.blue.shade700, Icons.schedule_send_rounded, l10n.relaySmsSending),
      RelaySmsOutcome.waiting => (Colors.orange.shade800, Icons.pause_circle_outline_rounded, l10n.relaySmsWaiting),
      RelaySmsOutcome.delivered => (
        Colors.green.shade700,
        Icons.check_circle_outline_rounded,
        l10n.relaySmsDelivered(targets.length),
      ),
      RelaySmsOutcome.partial => (
        Colors.orange.shade800,
        Icons.error_outline_rounded,
        l10n.relaySmsPartial(activity.deliveredCount, targets.length),
      ),
      RelaySmsOutcome.failed => (colorScheme.error, Icons.error_outline_rounded, l10n.relaySmsFailed),
      RelaySmsOutcome.blocked => (Colors.purple.shade700, Icons.block_rounded, l10n.relayStatusBlocked),
      RelaySmsOutcome.skipped => (
        colorScheme.onSurfaceVariant,
        Icons.remove_circle_outline_rounded,
        l10n.relayStatusSkipped,
      ),
    };
    final secondary = TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.sender.isEmpty ? l10n.relayLogUnknownSender : activity.sender,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
                if (formattedTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(formattedTime, style: secondary.copyWith(fontSize: 11)),
                  ),
                if (activity.detected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l10n.relayLogDetected(activity.detected), style: secondary),
                  ),
                for (final line in _detailLines(context))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(line, style: secondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gửi trọn vẹn → chỉ liệt kê tên kênh; còn lại → trạng thái từng kênh và
  /// lý do của kênh chưa gửi được (vd. "mở app để đồng bộ").
  List<String> _detailLines(BuildContext context) {
    final l10n = context.l10n;
    final channels = activity.channels;
    if (channels.isEmpty) return [if (activity.detail.isNotEmpty) activity.detail];

    if (activity.outcome == RelaySmsOutcome.delivered) {
      final names = activity.targets.map((c) => c.channelName).join(', ');
      return [l10n.relaySmsChannels(names)];
    }

    String statusLabel(RelayLogStatus status) => switch (status) {
      RelayLogStatus.success => l10n.relayStatusSuccess,
      RelayLogStatus.enqueued => l10n.relayStatusEnqueued,
      RelayLogStatus.retrying => l10n.relayStatusRetrying,
      RelayLogStatus.parked => l10n.relayStatusParked,
      RelayLogStatus.failed => l10n.relayStatusFailed,
      RelayLogStatus.blocked => l10n.relayStatusBlocked,
      RelayLogStatus.skipped => l10n.relayStatusSkipped,
      RelayLogStatus.unknown => l10n.relayStatusUnknown,
    };

    final perChannel = channels.map((c) => '${c.channelName}: ${statusLabel(c.status)}').join(' · ');
    final reason = channels
        .where((c) => c.isTarget && c.status != RelayLogStatus.success && c.detail.isNotEmpty)
        .map((c) => c.detail)
        .firstOrNull;
    return [perChannel, ?reason];
  }
}
