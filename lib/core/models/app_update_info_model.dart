import 'package:equatable/equatable.dart';

/// Thông tin cập nhật ứng dụng được cấu hình từ Firebase Remote Config.
class AppUpdateInfoModel extends Equatable {
  /// Build number mới nhất phát hành (ví dụ: 16).
  final int latestBuild;

  /// Version name mới nhất (ví dụ: "0.0.1").
  final String latestVersion;

  /// Build number tối thiểu bắt buộc để chạy app. Nếu build hiện tại < minBuild -> buộc cập nhật.
  final int minBuild;

  /// Tiêu đề popup thông báo.
  final String title;

  /// Nội dung mô tả / changelog ngắn.
  final String description;

  /// Đường dẫn tải bản mới (Firebase App Tester / Link APK / Web).
  final String downloadUrl;

  /// Cờ cập nhật bắt buộc (Force Update - không cho bỏ qua).
  final bool isForceUpdate;

  const AppUpdateInfoModel({
    required this.latestBuild,
    required this.latestVersion,
    required this.minBuild,
    required this.title,
    required this.description,
    required this.downloadUrl,
    required this.isForceUpdate,
  });

  /// Hàm thuần kiểm tra và đánh giá thông tin cập nhật (dễ dàng unit test không phụ thuộc Firebase).
  static AppUpdateInfoModel? evaluate({
    required int currentBuild,
    required String currentVersion,
    required int latestBuild,
    required String latestVersion,
    required int minBuild,
    required String title,
    required String description,
    required String downloadUrl,
  }) {
    if (latestBuild <= currentBuild) {
      return null;
    }

    final isForceUpdate = currentBuild < minBuild;

    return AppUpdateInfoModel(
      latestBuild: latestBuild,
      latestVersion: latestVersion.trim().isNotEmpty ? latestVersion.trim() : currentVersion,
      minBuild: minBuild,
      title: title.trim(),
      description: description.trim(),
      downloadUrl: downloadUrl.trim(),
      isForceUpdate: isForceUpdate,
    );
  }

  @override
  List<Object?> get props => [
        latestBuild,
        latestVersion,
        minBuild,
        title,
        description,
        downloadUrl,
        isForceUpdate,
      ];
}
