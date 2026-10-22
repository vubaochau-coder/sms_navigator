import '../models/activity_item.dart';

/// Use case của tab Hoạt động: nhật ký relay SMS của máy này + sự kiện kênh.
abstract class ActivityRepository {
  /// Mọi hoạt động, mới nhất trước.
  Future<List<ActivityItem>> loadActivity();

  /// Báo có hoạt động mới (sự kiện kênh vừa được ghi) để màn hình tự tải lại.
  Stream<void> get changes;
}
