import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/relay_log_model.dart';

/// Danh sách nhật ký chuyển tiếp gần đây — Soft Modern.
class SenderRecentLogsSection extends StatelessWidget {
  const SenderRecentLogsSection({super.key, required this.logs});

  final List<RelayLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhật Ký Chuyển Tiếp Gần Đây',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Center(
              child: Text(
                'Chưa có hoạt động chuyển tiếp OTP nào.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              final timeStr = DateFormat('HH:mm:ss dd/MM').format(
                DateTime.fromMillisecondsSinceEpoch(log.timestamp),
              );

              return _RelayLogTile(log: log, timeStr: timeStr);
            },
          ),
      ],
    );
  }
}

/// Một dòng nhật ký chuyển tiếp — Soft Modern.
class _RelayLogTile extends StatelessWidget {
  const _RelayLogTile({required this.log, required this.timeStr});

  final RelayLogModel log;
  final String timeStr;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuccess = log.status == 'SUCCESS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.successLight : AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.warning_amber_rounded,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.sender,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'OTP: ${log.otp.length > 2 ? "${log.otp.substring(0, 2)}****" : log.otp}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
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
