import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// Mockup trực quan dạng Heads-up banner của thông báo nhận OTP (Device B).
class ReceiverNotificationMockup extends StatelessWidget {
  const ReceiverNotificationMockup({
    super.key,
    required this.sender,
    required this.otp,
    required this.rawMessage,
    required this.colorScheme,
  });

  final String sender;
  final String otp;
  final String rawMessage;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'SMS NAVIGATOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'E2EE Verified',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'vừa xong',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '🔐 Mã OTP từ $sender',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OTP: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  otp,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2.0,
                    color: colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rawMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text(
                  'Sao chép mã',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: otp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã sao chép mã $otp')),
                  );
                },
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Mở chi tiết',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mockup trực quan thông báo chuyển tiếp OTP thành công (Device A).
class SenderNotificationMockup extends StatelessWidget {
  const SenderNotificationMockup({
    super.key,
    required this.sender,
    required this.otp,
    required this.targetDevice,
    required this.colorScheme,
  });

  final String sender;
  final String otp;
  final String targetDevice;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SMS NAVIGATOR • RELAY SENDER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: cs.primary,
                  ),
                ),
              ),
              Text(
                'vừa xong',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '✅ Chuyển Tiếp OTP Thành Công',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đã chuyển mã $otp (từ $sender) tới $targetDevice an toàn qua đường truyền mã hóa E2EE.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
