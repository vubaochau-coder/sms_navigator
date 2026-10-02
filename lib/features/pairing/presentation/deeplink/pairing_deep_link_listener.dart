import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/deep_link_service.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../data/models/pairing_payload_model.dart';
import '../pages/pairing_deep_link_confirm_page.dart';

/// Lắng nghe deep link mở app (GĐ3): QR ghép đôi v3 là URL
/// `smsnavigator://pair?...` — camera hệ thống hoặc app quét của bên thứ ba
/// mở thẳng app. URI hợp lệ được đẩy vào trang xác nhận ghép đôi; URI khác
/// được bỏ qua (sẵn sàng thêm loại deep link mới sau này).
class PairingDeepLinkListener extends StatefulWidget {
  const PairingDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<PairingDeepLinkListener> createState() =>
      _PairingDeepLinkListenerState();
}

class _PairingDeepLinkListenerState extends State<PairingDeepLinkListener> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<DeepLinkService>().uriStream.listen(
      _handleUri,
    );
  }

  void _handleUri(Uri uri) {
    final raw = uri.toString();
    if (!PairingPayloadModel.looksLikePairingQr(raw)) return;
    final navigator = DialogUtils.navigatorKey.currentState;
    navigator?.push(
      MaterialPageRoute<void>(
        builder: (_) => PairingDeepLinkConfirmPage(qrData: raw),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
