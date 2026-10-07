import 'package:flutter/widgets.dart';

import '../services/sync_owner_relay_channel_use_case.dart';
import '../utils/app_logger.dart';

/// Observer theo dõi vòng đời ứng dụng (Foreground / Background).
/// Tự động kích hoạt đồng bộ Kênh Owner & Channel Key khi app chuyển sang trạng thái resumed.
class AppLifecycleObserver with WidgetsBindingObserver {
  final SyncOwnerRelayChannelUseCase _syncUseCase;
  bool _isRegistered = false;

  AppLifecycleObserver({
    required SyncOwnerRelayChannelUseCase syncUseCase,
  }) : _syncUseCase = syncUseCase;

  void register() {
    if (_isRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _isRegistered = true;
  }

  void unregister() {
    if (!_isRegistered) return;
    WidgetsBinding.instance.removeObserver(this);
    _isRegistered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.i('AppLifecycleObserver', 'App resumed, syncing active owner relay channel to native.');
      _syncUseCase().catchError((_) => false);
    }
  }
}
