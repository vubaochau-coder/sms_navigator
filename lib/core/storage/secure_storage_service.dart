import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kho lưu trữ bảo mật (Keychain/Keystore) cho dữ liệu nhạy cảm
/// (roadmap GĐ4.1): shared secret ECDH, device token.
///
/// Thay thế shared_preferences cho các giá trị mà kẻ có root/copy dữ liệu
/// app có thể khai thác. Tầng trên phụ thuộc abstraction này, không đụng
/// trực tiếp vào FlutterSecureStorage.
abstract class SecureStorageService {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);
}

class SecureStorageServiceImpl implements SecureStorageService {
  SecureStorageServiceImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}
