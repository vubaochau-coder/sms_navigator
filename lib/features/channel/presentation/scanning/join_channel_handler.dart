import 'package:flutter/material.dart';

import '../../../scanner/presentation/scanning/qr_scan_handler.dart';
import '../pages/join_confirm_page.dart';

/// Handler cho invite QR v4 (`smsnavigator://pair?v=4&...`) — thêm handler
/// này vào scanner trung tính, không sửa scanner (GĐ0/GĐ3).
///
/// §18.2 SOLUTION: KHÔNG tự gọi API sau khi quét — chỉ điều hướng sang
/// JoinConfirmPage để user bấm [Gửi yêu cầu kết nối] mới claim.
class JoinChannelHandler implements QrScanHandler {
  @override
  bool canHandle(String raw) => raw.trim().startsWith('smsnavigator://pair?');

  @override
  void handleScan(BuildContext context, QrScanFlow flow, String raw) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => JoinConfirmPage(inviteRaw: raw),
          ),
        )
        .whenComplete(() => flow.complete());
  }

  @override
  void dispose() {}
}

/// Alias dùng khi dựng registry cho scanner.
typedef QrScanFlowController = QrScanFlow;
