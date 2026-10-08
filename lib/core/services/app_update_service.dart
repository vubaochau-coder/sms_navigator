import '../models/app_update_info_model.dart';

abstract class AppUpdateService {
  /// Kiểm tra có bản cập nhật mới hay không từ Remote Config.
  /// Trả về [AppUpdateInfoModel] nếu có bản mới, hoặc null nếu không có hoặc lỗi mạng.
  Future<AppUpdateInfoModel?> checkForUpdate();

  /// Ghi nhận người dùng chọn "Để sau" cho một build number cụ thể.
  Future<void> dismissUpdate(int buildNumber);

  /// Kiểm tra xem build number này đã từng bị người dùng chọn "Để sau" chưa.
  bool isUpdateDismissed(int buildNumber);
}
