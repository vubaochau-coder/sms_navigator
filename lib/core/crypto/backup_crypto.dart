import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../errors/app_exceptions.dart';

/// Lý do mở bản sao lưu thất bại — UI map sang thông điệp tiếng Việt.
enum BackupFailure {
  /// Không phải file `.smsnav` / JSON hỏng / thiếu trường.
  invalidFile,

  /// Định dạng mới hơn bản app này hiểu được.
  unsupportedVersion,

  /// Sai passphrase (hoặc file bị sửa — GCM tag không khớp).
  wrongPassphrase,

  /// Giải mã được nhưng nội dung thiếu danh tính.
  incompleteBackup,

  /// Người dùng huỷ chọn / lưu file.
  cancelled,

  /// Máy chưa đăng ký với server — chưa có gì để sao lưu.
  notRegistered,

  /// Lỗi đọc/ghi file hoặc lỗi không xác định.
  storage,
}

class BackupException extends AppException {
  const BackupException(this.failure, [super.message = 'Backup error']);

  final BackupFailure failure;

  @override
  String toString() => 'BackupException(${failure.name}): $message';
}

/// Container mã hoá cho bản sao lưu `.smsnav` (BACKLOG 1.1).
///
/// ```jsonc
/// {
///   "format": "smsnav-backup", "version": 1,
///   "kdf":    { "alg": "PBKDF2-HMAC-SHA256", "iterations": 310000, "salt": "<b64 16B>" },
///   "cipher": { "alg": "AES-256-GCM", "nonce": "<b64 12B>" },
///   "ciphertext": "<b64 ciphertext || 16B tag>"
/// }
/// ```
///
/// - Key = PBKDF2-HMAC-SHA256(passphrase nguyên văn UTF-8, salt ngẫu nhiên
///   16 byte, [defaultIterations] vòng) — không trim / chuẩn hoá passphrase.
/// - AAD = `smsnav-backup|v1` → đổi header version sẽ làm hỏng tag.
/// - KDF chạy trong isolate riêng (vài giây trên máy yếu) để không treo UI.
class BackupCrypto {
  BackupCrypto({this.iterations = defaultIterations, Random? random})
    : _random = random ?? Random.secure();

  static const String format = 'smsnav-backup';
  static const int version = 1;
  static const String fileExtension = 'smsnav';

  /// OWASP (2021) cho PBKDF2-HMAC-SHA256. Lưu trong header nên có thể tăng
  /// về sau mà file cũ vẫn mở được.
  static const int defaultIterations = 310000;

  /// Chặn file bị sửa header để bắt máy chạy KDF quá lâu (hoặc quá yếu).
  static const int minIterations = 100000;
  static const int maxIterations = 5000000;

  static const int minPassphraseLength = 10;

  final int iterations;
  final Random _random;

  static final List<int> _aad = utf8.encode('$format|v$version');

  Future<Uint8List> seal({required String plaintext, required String passphrase}) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await deriveKey(passphrase: passphrase, salt: salt, iterations: iterations);

    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: _aad,
    );

    final envelope = <String, Object>{
      'format': format,
      'version': version,
      'kdf': <String, Object>{
        'alg': 'PBKDF2-HMAC-SHA256',
        'iterations': iterations,
        'salt': base64Encode(salt),
      },
      'cipher': <String, Object>{
        'alg': 'AES-256-GCM',
        'nonce': base64Encode(nonce),
      },
      'ciphertext': base64Encode([...box.cipherText, ...box.mac.bytes]),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  /// Ném [BackupException] với [BackupFailure.invalidFile],
  /// [BackupFailure.unsupportedVersion] hoặc [BackupFailure.wrongPassphrase].
  Future<String> open({required Uint8List bytes, required String passphrase}) async {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException(BackupFailure.invalidFile, 'Not a JSON backup envelope');
    }
    if (envelope['format'] != format) {
      throw const BackupException(BackupFailure.invalidFile, 'Unknown format');
    }
    final fileVersion = envelope['version'];
    if (fileVersion is! int || fileVersion < 1) {
      throw const BackupException(BackupFailure.invalidFile, 'Missing version');
    }
    if (fileVersion > version) {
      throw const BackupException(BackupFailure.unsupportedVersion, 'Backup made by a newer app');
    }

    final List<int> salt;
    final List<int> nonce;
    final List<int> sealed;
    final int fileIterations;
    try {
      final kdf = envelope['kdf'] as Map<String, dynamic>;
      final cipher = envelope['cipher'] as Map<String, dynamic>;
      if (kdf['alg'] != 'PBKDF2-HMAC-SHA256' || cipher['alg'] != 'AES-256-GCM') {
        throw const FormatException('Unsupported algorithms');
      }
      fileIterations = kdf['iterations'] as int;
      salt = base64Decode(kdf['salt'] as String);
      nonce = base64Decode(cipher['nonce'] as String);
      sealed = base64Decode(envelope['ciphertext'] as String);
    } catch (_) {
      throw const BackupException(BackupFailure.invalidFile, 'Malformed envelope');
    }
    if (fileIterations < minIterations ||
        fileIterations > maxIterations ||
        salt.length < 16 ||
        nonce.length != 12 ||
        sealed.length <= 16) {
      throw const BackupException(BackupFailure.invalidFile, 'Envelope parameters out of range');
    }

    final key = await deriveKey(passphrase: passphrase, salt: salt, iterations: fileIterations);
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(
          sealed.sublist(0, sealed.length - 16),
          nonce: nonce,
          mac: Mac(sealed.sublist(sealed.length - 16)),
        ),
        secretKey: SecretKey(key),
        aad: _aad,
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupFailure.wrongPassphrase, 'Authentication failed');
    } on FormatException {
      throw const BackupException(BackupFailure.invalidFile, 'Plaintext is not UTF-8');
    }
  }

  /// PBKDF2 trong isolate riêng. Static: closure không được bắt `this`
  /// ([Random] không gửi qua isolate được).
  static Future<List<int>> deriveKey({
    required String passphrase,
    required List<int> salt,
    required int iterations,
  }) {
    return Isolate.run(() => _derive(passphrase, salt, iterations));
  }

  static Future<List<int>> _derive(String passphrase, List<int> salt, int iterations) async {
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final key = await pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
    return key.extractBytes();
  }

  List<int> _randomBytes(int length) => List<int>.generate(length, (_) => _random.nextInt(256));
}
