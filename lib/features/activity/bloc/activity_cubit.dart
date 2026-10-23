import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/activity_repository.dart';
import '../../../core/utils/app_logger.dart';
import 'activity_state.dart';

/// Tab Hoạt động: tải nhật ký relay + sự kiện kênh, tự làm mới khi có sự kiện mới.
class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({
    required ActivityRepository repository,
    this.minFeedbackDuration = const Duration(milliseconds: 450),
  })  : _repository = repository,
        super(const ActivityState()) {
    _changes = _repository.changes.listen((_) => refresh());
  }

  final ActivityRepository _repository;
  StreamSubscription<void>? _changes;

  /// Nhật ký nằm sẵn trên máy nên tải gần như tức thì — shimmer / vòng xoay
  /// chỉ chớp một khung hình. Khi người dùng chủ động làm mới, giữ phản hồi
  /// tối thiểu chừng này để thấy là app đã phản ứng.
  final Duration minFeedbackDuration;

  /// [userInitiated]: mở tab, bấm nút hoặc kéo để làm mới → có phản hồi
  /// tối thiểu [minFeedbackDuration]. Làm mới tự động khi có sự kiện mới thì
  /// cập nhật lặng lẽ. [showSkeleton]: thay danh sách bằng shimmer trong lúc tải
  /// (kéo để làm mới đã có vòng xoay riêng nên không cần).
  Future<void> refresh({bool userInitiated = false, bool showSkeleton = false}) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, showSkeleton: showSkeleton ? true : null));
    final minDelay = userInitiated ? Future<void>.delayed(minFeedbackDuration) : Future<void>.value();
    try {
      final items = await _repository.loadActivity();
      await minDelay;
      if (isClosed) return;
      emit(state.copyWith(items: items, isLoading: false, showSkeleton: false, hasLoaded: true));
    } catch (e) {
      AppLogger.w('ActivityCubit', 'Cannot load activity', e);
      await minDelay;
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, showSkeleton: false, hasLoaded: true));
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
