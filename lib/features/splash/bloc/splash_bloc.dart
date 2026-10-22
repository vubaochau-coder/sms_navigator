import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/enums/splash_status.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/repositories/startup_repository.dart';
import '../../../core/utils/app_logger.dart';
import 'splash_event.dart';
import 'splash_state.dart';
import '../../../core/l10n/app_l10n.dart';

/// Màn khởi động: chỉ còn phụ thuộc [StartupRepository] (BACKLOG 3.3) — bloc
/// lo thời gian hiển thị tối thiểu, lựa chọn thiết lập / khôi phục và thông
/// điệp lỗi; các bước khởi động nằm trong repository.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final StartupRepository startupRepository;
  final Duration minDisplayDuration;

  /// Bản cài chưa đăng ký → dừng ở [SplashStatus.awaitingSetupChoice] để
  /// người dùng có thể khôi phục từ bản sao lưu thay vì tạo danh tính mới.
  /// Tắt (mặc định) → tự đăng ký như trước.
  final bool offerRestoreOnFirstRun;

  CancelToken? _cancelToken;
  bool _newDeviceConfirmed = false;

  SplashBloc({
    required this.startupRepository,
    this.minDisplayDuration = const Duration(milliseconds: 1200),
    this.offerRestoreOnFirstRun = false,
  }) : super(const SplashState()) {
    on<SplashStarted>(_onStarted, transformer: droppable());
    on<SplashRetried>(_onRetried, transformer: restartable());
    on<SplashNewDeviceChosen>(_onNewDeviceChosen, transformer: droppable());
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('SplashBloc closed');
    return super.close();
  }

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    _cancelToken = CancelToken();
    await _executeBootstrap(
      defaultDeviceName: event.defaultDeviceName,
      emit: emit,
    );
  }

  Future<void> _onRetried(
    SplashRetried event,
    Emitter<SplashState> emit,
  ) async {
    _cancelToken?.cancel('SplashRetried triggered');
    _cancelToken = CancelToken();
    await _executeBootstrap(
      defaultDeviceName: event.defaultDeviceName,
      emit: emit,
    );
  }

  Future<void> _onNewDeviceChosen(
    SplashNewDeviceChosen event,
    Emitter<SplashState> emit,
  ) async {
    _newDeviceConfirmed = true;
    _cancelToken?.cancel('SplashNewDeviceChosen triggered');
    _cancelToken = CancelToken();
    await _executeBootstrap(
      defaultDeviceName: event.defaultDeviceName,
      emit: emit,
    );
  }

  Future<void> _executeBootstrap({
    required String defaultDeviceName,
    required Emitter<SplashState> emit,
  }) async {
    final stopwatch = Stopwatch()..start();
    emit(state.copyWith(status: SplashStatus.initializingServices, clearError: true));

    try {
      await for (final status in startupRepository.bootstrap(
        defaultDeviceName: defaultDeviceName,
        offerSetupChoice: offerRestoreOnFirstRun && !_newDeviceConfirmed,
        cancelToken: _cancelToken,
      )) {
        if (status == SplashStatus.ready) break;
        emit(state.copyWith(status: status));
        if (status == SplashStatus.awaitingSetupChoice) return;
      }

      // Đảm bảo thời gian hiển thị tối thiểu để animation hiển thị chỉn chu
      if (minDisplayDuration > Duration.zero) {
        final remaining = minDisplayDuration.inMilliseconds - stopwatch.elapsedMilliseconds;
        if (remaining > 0) {
          await Future<void>.delayed(Duration(milliseconds: remaining));
        }
      }

      emit(state.copyWith(status: SplashStatus.ready));
    } on RequestCancelledException {
      AppLogger.d('SplashBloc', 'Bootstrap was cancelled for retry');
    } catch (error, stack) {
      AppLogger.e('SplashBloc', 'Bootstrap error', error, stack);
      await startupRepository.recordFailure(error, stack);

      final String userFriendlyMessage;
      final SplashFailureKind kind;
      if (error is NetworkException) {
        userFriendlyMessage = error.message;
        kind = SplashFailureKind.network;
      } else if (error is ApiException) {
        userFriendlyMessage = AppL10n.current.splashServerError('${error.statusCode ?? 'Unknown'}');
        kind = SplashFailureKind.server;
      } else if (error is StateError) {
        userFriendlyMessage = error.message;
        kind = SplashFailureKind.unknown;
      } else {
        userFriendlyMessage = AppL10n.current.splashStartupFailed;
        kind = SplashFailureKind.unknown;
      }

      emit(state.copyWith(
        status: SplashStatus.failure,
        errorMessage: userFriendlyMessage,
        failureKind: kind,
      ));
    }
  }
}
