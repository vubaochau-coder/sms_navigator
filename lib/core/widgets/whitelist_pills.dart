import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../models/whitelist_config_model.dart';

/// Một pill trong hàng white-list.
class WhitelistPillData extends Equatable {
  const WhitelistPillData.address(this.label, {this.allowOtp = false})
      : kind = WhitelistPillKind.address,
        overflowCount = 0;

  const WhitelistPillData.allSenders()
      : kind = WhitelistPillKind.allSenders,
        label = '',
        allowOtp = false,
        overflowCount = 0;

  const WhitelistPillData.overflow(this.overflowCount)
      : kind = WhitelistPillKind.overflow,
        label = '',
        allowOtp = false;

  final WhitelistPillKind kind;
  final String label;
  final bool allowOtp;
  final int overflowCount;

  /// Chế độ "nhận mọi địa chỉ" là một pill riêng đứng đầu; sau đó là từng
  /// địa chỉ. Có [maxPills] và vượt quá → pill cuối là "+N" (N = số còn lại).
  static List<WhitelistPillData> fromConfig(WhitelistConfigModel config, {int? maxPills}) {
    final pills = <WhitelistPillData>[
      if (config.mode == WhitelistMode.allAddresses) const WhitelistPillData.allSenders(),
      for (final entry in config.entries) WhitelistPillData.address(entry.address, allowOtp: entry.allowOtp),
    ];
    if (maxPills == null || pills.length <= maxPills) return pills;
    final shown = maxPills - 1;
    return [...pills.take(shown), WhitelistPillData.overflow(pills.length - shown)];
  }

  @override
  List<Object?> get props => [kind, label, allowOtp, overflowCount];
}

enum WhitelistPillKind { address, allSenders, overflow }

/// Hàng pill brandname / số điện thoại trong white-list của kênh (chỉ xem).
class WhitelistPills extends StatelessWidget {
  const WhitelistPills({super.key, required this.config, this.maxPills, this.showOtpMarker = false});

  final WhitelistConfigModel config;

  /// null → hiện tất cả (trang chi tiết); danh sách kênh dùng 3.
  final int? maxPills;

  /// Đánh dấu địa chỉ được phép gửi OTP (trang chi tiết).
  final bool showOtpMarker;

  @override
  Widget build(BuildContext context) {
    final pills = WhitelistPillData.fromConfig(config, maxPills: maxPills);
    if (pills.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final pill in pills) _WhitelistPill(pill: pill, showOtpMarker: showOtpMarker),
      ],
    );
  }
}

class _WhitelistPill extends StatelessWidget {
  const _WhitelistPill({required this.pill, required this.showOtpMarker});

  final WhitelistPillData pill;
  final bool showOtpMarker;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isAddress = pill.kind == WhitelistPillKind.address;
    final background = isAddress ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest;
    final foreground = isAddress ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant;
    final text = switch (pill.kind) {
      WhitelistPillKind.address => pill.label,
      WhitelistPillKind.allSenders => l10n.whitelistPillAllSenders,
      WhitelistPillKind.overflow => l10n.whitelistPillOverflow(pill.overflowCount),
    };
    final showOtp = showOtpMarker && pill.allowOtp;

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: foreground),
            ),
          ),
          if (showOtp) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: l10n.whitelistPillOtpAllowed,
              child: Icon(Icons.key_rounded, size: 12, color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}
