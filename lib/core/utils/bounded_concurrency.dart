import 'dart:math';

/// Chạy [action] cho từng phần tử, tối đa [concurrency] việc cùng lúc.
///
/// Dùng cho các vòng gọi API theo từng kênh lúc khởi động (BACKLOG 3.4):
/// nhanh hơn tuần tự nhưng không dồn N request lên server cùng một lúc.
/// [action] nên tự bắt lỗi; lỗi lọt ra sẽ được ném lại sau khi mọi việc
/// đang chạy kết thúc (lỗi đầu tiên).
Future<void> forEachBounded<T>(
  Iterable<T> items,
  Future<void> Function(T item) action, {
  int concurrency = 4,
}) async {
  assert(concurrency > 0);
  final list = items.toList(growable: false);
  if (list.isEmpty) return;

  var next = 0;
  Object? firstError;
  StackTrace? firstStack;

  Future<void> worker() async {
    while (next < list.length) {
      final item = list[next++];
      try {
        await action(item);
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
  }

  await Future.wait(List.generate(min(concurrency, list.length), (_) => worker()));
  final error = firstError;
  if (error != null) Error.throwWithStackTrace(error, firstStack ?? StackTrace.current);
}
