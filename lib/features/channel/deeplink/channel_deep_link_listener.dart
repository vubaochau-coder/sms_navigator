import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/deep_link_service.dart';
import '../pages/join_confirm_page.dart';

/// Lắng nghe deep link invite v4 (`smsnavigator://pair?v=4&...`): camera hệ
/// thống / app quét của bên thứ ba mở thẳng app → JoinConfirmPage. URI khác
/// được bỏ qua (sẵn sàng thêm loại deep link mới sau này — GĐ0).
class ChannelDeepLinkListener extends StatefulWidget {
  const ChannelDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<ChannelDeepLinkListener> createState() =>
      _ChannelDeepLinkListenerState();
}

class _ChannelDeepLinkListenerState extends State<ChannelDeepLinkListener> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<DeepLinkService>().uriStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    final raw = uri.toString();
    if (!raw.startsWith('smsnavigator://pair?')) return;
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => JoinConfirmPage(inviteRaw: raw)),
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
