import 'package:equatable/equatable.dart';

import 'relay_log_entry.dart';

/// Kết quả chung của một SMS trên mọi kênh — một mục trên tab Hoạt động.
enum RelaySmsOutcome {
  /// Còn ít nhất một kênh đang chờ worker gửi / thử lại.
  sending,

  /// Không còn kênh nào đang gửi, nhưng có kênh đang tạm giữ tin (chờ mở app
  /// để đồng bộ khoá / đăng ký lại).
  waiting,

  /// Đã gửi tới mọi kênh nhận tin này.
  delivered,

  /// Gửi được tới một phần số kênh, phần còn lại lỗi.
  partial,

  /// Không gửi được tới kênh nào.
  failed,

  /// Mọi kênh đều lọc bỏ tin (white-list).
  blocked,

  /// Không gửi: không có kênh, tin trùng…
  skipped,
}

/// Trạng thái cuối cùng của SMS trên một kênh (dòng nhật ký mới nhất của kênh đó).
class RelaySmsChannelResult extends Equatable {
  const RelaySmsChannelResult({
    required this.channelId,
    required this.channelName,
    required this.status,
    this.detail = '',
  });

  final String channelId;
  final String channelName;
  final RelayLogStatus status;
  final String detail;

  /// Kênh có thật sự nhận tin để gửi (không bị lọc / bỏ qua).
  bool get isTarget => status != RelayLogStatus.blocked && status != RelayLogStatus.skipped;

  @override
  List<Object?> get props => [channelId, channelName, status, detail];
}

/// Mọi dòng nhật ký native của cùng một SMS (`sms_id`) gộp lại.
class RelaySmsActivity extends Equatable {
  const RelaySmsActivity({
    required this.smsId,
    required this.sender,
    required this.channels,
    this.detected = '',
    this.at,
    this.detail = '',
  });

  /// Gom các dòng cùng `smsId`. [entries] theo thứ tự bất kỳ; dòng không có
  /// `smsId` không thuộc về hàm này.
  factory RelaySmsActivity.fromEntries(String smsId, List<RelayLogEntry> entries) {
    final sorted = [...entries]..sort((a, b) {
        final aAt = a.at, bAt = b.at;
        if (aAt == null || bAt == null) return 0;
        return aAt.compareTo(bAt);
      });

    final latestByChannel = <String, RelaySmsChannelResult>{};
    var sender = '';
    var detected = '';
    var detail = '';
    DateTime? at;
    for (final entry in sorted) {
      at ??= entry.at;
      if (sender.isEmpty) sender = entry.sender;
      if (detected.isEmpty) detected = entry.detected;
      if (entry.channelId.isEmpty) {
        // Dòng chung của SMS (vd. chưa có kênh nào) — giữ lý do mới nhất.
        detail = entry.detail;
        continue;
      }
      final previous = latestByChannel[entry.channelId];
      latestByChannel[entry.channelId] = RelaySmsChannelResult(
        channelId: entry.channelId,
        channelName: entry.channelName.isNotEmpty
            ? entry.channelName
            : (previous?.channelName ?? entry.channelId),
        status: entry.status,
        detail: entry.detail,
      );
    }

    return RelaySmsActivity(
      smsId: smsId,
      sender: sender,
      detected: detected,
      at: at,
      detail: detail,
      channels: latestByChannel.values.toList(),
    );
  }

  final String smsId;
  final String sender;

  /// OTP đã che hoặc `SMS`.
  final String detected;

  /// Lúc nhận SMS (dòng nhật ký sớm nhất) — mục không nhảy chỗ khi kết quả về.
  final DateTime? at;

  /// Lý do chung khi SMS không đi tới kênh nào (không có kênh, lỗi đọc tin…).
  final String detail;
  final List<RelaySmsChannelResult> channels;

  List<RelaySmsChannelResult> get targets => channels.where((c) => c.isTarget).toList();

  int get deliveredCount => channels.where((c) => c.status == RelayLogStatus.success).length;

  RelaySmsOutcome get outcome {
    final targets = this.targets;
    if (targets.isEmpty) {
      return channels.any((c) => c.status == RelayLogStatus.blocked)
          ? RelaySmsOutcome.blocked
          : RelaySmsOutcome.skipped;
    }
    bool any(Set<RelayLogStatus> statuses) => targets.any((c) => statuses.contains(c.status));
    if (any({RelayLogStatus.enqueued, RelayLogStatus.retrying, RelayLogStatus.unknown})) {
      return RelaySmsOutcome.sending;
    }
    if (any({RelayLogStatus.parked})) return RelaySmsOutcome.waiting;
    final delivered = deliveredCount;
    if (delivered == targets.length) return RelaySmsOutcome.delivered;
    return delivered > 0 ? RelaySmsOutcome.partial : RelaySmsOutcome.failed;
  }

  @override
  List<Object?> get props => [smsId, sender, detected, at, detail, channels];
}
