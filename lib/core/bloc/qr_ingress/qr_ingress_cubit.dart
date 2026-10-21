import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/qr_repository.dart';
import '../../services/deep_link_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/qr_link_parser.dart';
import '../../utils/qr_error_messages.dart';
import 'qr_ingress_state.dart';

export 'qr_ingress_state.dart';

/// Cổng vào duy nhất cho mọi mã QR / deeplink (roadmap v3.3 §1):
/// camera, ảnh, deeplink hệ điều hành và "Dán mã" đều gọi [submit].
///
/// Sống ở cấp app (tạo ngay khi khởi động — `lazy: false`) để không lỡ
/// deeplink cold start; giữ mã trong [QrIngressState.pending] cho tới khi
/// màn hình chính sẵn sàng [consume].
class QrIngressCubit extends Cubit<QrIngressState> {
  QrIngressCubit({
    required QrRepository repository,
    DeepLinkService? deepLinks,
    Duration duplicateWindow = const Duration(seconds: 3),
    DateTime Function() clock = DateTime.now,
  }) : _repository = repository,
       _duplicateWindow = duplicateWindow,
       _clock = clock,
       super(const QrIngressState()) {
    _subscription = deepLinks?.links.listen((uri) => submit(uri.toString()));
  }

  final QrRepository _repository;
  final Duration _duplicateWindow;
  final DateTime Function() _clock;
  StreamSubscription<Uri>? _subscription;

  String? _lastRaw;
  DateTime? _lastAt;

  Future<void> submit(String raw) async {
    final value = raw.trim();
    final now = _clock();
    // The OS can re-deliver the launch link (initial + stream); ignore echoes.
    if (value == _lastRaw && _lastAt != null && now.difference(_lastAt!) < _duplicateWindow) {
      return;
    }
    _lastRaw = value;
    _lastAt = now;

    Set<String> hosts = const {};
    try {
      hosts = await _repository.allowedLinkHosts();
    } catch (e) {
      AppLogger.w('QrIngress', 'Cannot load allowed hosts', e);
    }
    if (isClosed) return;

    final link = QrLinkParser.parse(value, allowedHosts: hosts);
    if (link == null) {
      emit(state.copyWith(
        rejectionMessage: QrErrorMessages.unsupportedFormat,
        rejectionSeq: state.rejectionSeq + 1,
      ));
      return;
    }
    emit(state.copyWith(pending: link, pendingSeq: state.pendingSeq + 1));
  }

  /// Lấy mã đang chờ (một lần duy nhất).
  QrLink? consume() {
    final link = state.pending;
    if (link != null) emit(state.copyWith(clearPending: true));
    return link;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
