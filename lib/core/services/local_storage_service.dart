import 'impls/local_storage_service_impl.dart';

/// Service trung tâm duy nhất quản lý Local Storage (SharedPreferences).
///
/// Toàn bộ ứng dụng KHÔNG được gọi trực tiếp `SharedPreferences.getInstance()`
/// mà phải đi qua service này (trừ AppBootstrap dùng factory create).
/// Các key bắt buộc lấy từ StorageKeys để tránh hardcode rải rác.
abstract class LocalStorageService {
  static Future<LocalStorageService> create() =>
      LocalStorageServiceImpl.create();

  String? getString(String key);

  Future<void> setString(String key, String value);

  bool? getBool(String key);

  Future<void> setBool(String key, bool value);

  Future<void> remove(String key);
}
