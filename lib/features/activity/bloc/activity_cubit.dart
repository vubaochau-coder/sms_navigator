import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/activity_repository.dart';
import '../../../core/utils/app_logger.dart';
import 'activity_state.dart';

/// Tab Hoạt động: tải nhật ký relay + sự kiện kênh, tự làm mới khi có sự kiện mới.
class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({required ActivityRepository repository})
      : _repository = repository,
        super(const ActivityState()) {
    _changes = _repository.changes.listen((_) => refresh());
  }

  final ActivityRepository _repository;
  StreamSubscription<void>? _changes;

  Future<void> refresh() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _repository.loadActivity();
      if (isClosed) return;
      emit(state.copyWith(items: items, isLoading: false, hasLoaded: true));
    } catch (e) {
      AppLogger.w('ActivityCubit', 'Cannot load activity', e);
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, hasLoaded: true));
    }
  }

  void selectFilter(ActivityFilter filter) {
    if (filter != state.filter) emit(state.copyWith(filter: filter));
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
