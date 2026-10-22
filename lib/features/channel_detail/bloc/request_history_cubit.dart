import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/pairing_request_model.dart';
import '../../../core/repositories/channel_repository.dart';
import '../../../core/utils/app_logger.dart';

class RequestHistoryState extends Equatable {
  final List<PairingRequestModel> items;
  final String? nextBefore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasError;

  const RequestHistoryState({
    this.items = const [],
    this.nextBefore,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasError = false,
  });

  bool get hasMore => nextBefore != null;

  RequestHistoryState copyWith({
    List<PairingRequestModel>? items,
    String? Function()? nextBefore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasError,
  }) {
    return RequestHistoryState(
      items: items ?? this.items,
      nextBefore: nextBefore != null ? nextBefore() : this.nextBefore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  List<Object?> get props => [items, nextBefore, isLoading, isLoadingMore, hasError];
}

/// Lịch sử request đã xử lý của 1 kênh (Owner, BACKLOG 1.6).
class RequestHistoryCubit extends Cubit<RequestHistoryState> {
  RequestHistoryCubit({required ChannelRepository repository, required this.channelId})
      : _repository = repository,
        super(const RequestHistoryState());

  final ChannelRepository _repository;
  final String channelId;

  Future<void> load() async {
    emit(const RequestHistoryState(isLoading: true));
    try {
      final page = await _repository.listRequestHistory(channelId);
      emit(RequestHistoryState(items: page.items, nextBefore: page.nextBefore));
    } catch (e) {
      AppLogger.w('RequestHistory', 'Load failed for $channelId', e);
      emit(const RequestHistoryState(hasError: true));
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextBefore;
    if (cursor == null || state.isLoadingMore || state.isLoading) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.listRequestHistory(channelId, before: cursor);
      emit(state.copyWith(
        items: [...state.items, ...page.items],
        nextBefore: () => page.nextBefore,
        isLoadingMore: false,
      ));
    } catch (e) {
      AppLogger.w('RequestHistory', 'Load more failed for $channelId', e);
      emit(state.copyWith(isLoadingMore: false));
    }
  }
}
