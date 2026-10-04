import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/crashlytics_service.dart';

/// BLoC Observer ghi nhận toàn bộ vòng đời, state transitions và ngoại lệ
/// bất thường xảy ra trong quá trình sử dụng BLoC/Cubit.
class AppBlocObserver extends BlocObserver {
  final CrashlyticsService _crashlytics;

  AppBlocObserver({CrashlyticsService? crashlytics})
      : _crashlytics = crashlytics ?? CrashlyticsService.instance;

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('💥 [BLoC Error] in ${bloc.runtimeType}: $error\n$stackTrace');
    _crashlytics.recordError(
      error,
      stackTrace,
      reason: 'Unhandled exception in ${bloc.runtimeType}',
      fatal: false,
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _crashlytics.log(
      '[BLoC] ${bloc.runtimeType}: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}',
    );
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _crashlytics.log('[BLoC Event] ${bloc.runtimeType}: ${event.runtimeType}');
  }
}
