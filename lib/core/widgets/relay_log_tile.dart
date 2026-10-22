import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../models/relay_log_entry.dart';
import '../utils/date_time_utils.dart';

/// Một dòng nhật ký relay SMS (trang Bộ lọc và tab Hoạt động).
class RelayLogTile extends StatelessWidget {
  const RelayLogTile({super.key, required this.entry});

  final RelayLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;
    final at = entry.at;
    final formattedTime = at != null ? DateTimeUtils.formatDate(at, pattern: 'HH:mm:ss · dd/MM/yyyy') : '';

    final (Color color, IconData icon, String label) = switch (entry.status) {
      RelayLogStatus.success => (Colors.green.shade700, Icons.check_circle_outline_rounded, l10n.relayStatusSuccess),
      RelayLogStatus.enqueued => (Colors.blue.shade700, Icons.schedule_send_rounded, l10n.relayStatusEnqueued),
      RelayLogStatus.retrying => (Colors.orange.shade800, Icons.refresh_rounded, l10n.relayStatusRetrying),
      RelayLogStatus.parked => (Colors.orange.shade800, Icons.pause_circle_outline_rounded, l10n.relayStatusParked),
      RelayLogStatus.failed => (colorScheme.error, Icons.error_outline_rounded, l10n.relayStatusFailed),
      RelayLogStatus.blocked => (Colors.purple.shade700, Icons.block_rounded, l10n.relayStatusBlocked),
      RelayLogStatus.skipped => (colorScheme.onSurfaceVariant, Icons.remove_circle_outline_rounded, l10n.relayStatusSkipped),
      RelayLogStatus.unknown => (colorScheme.onSurfaceVariant, Icons.help_outline_rounded, l10n.relayStatusUnknown),
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
                        entry.sender.isEmpty ? l10n.relayLogUnknownSender : entry.sender,
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
                if (entry.detected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l10n.relayLogDetected(entry.detected), style: secondary),
                  ),
                if (entry.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(entry.detail, style: secondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
