import 'dart:convert';
import 'dart:typed_data';

import '../../crypto/backup_crypto.dart';
import '../../crypto/channel_crypto_helper.dart';
import '../../models/backup_payload.dart';
import '../../services/backup_file_service.dart';
import '../../services/channel_key_store.dart';
import '../../services/device_storage_service.dart';
import '../backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl({
    required DeviceStorageService deviceStorage,
    required ChannelKeyStore keyStore,
    required ChannelKeyArchive keyArchive,
    required BackupFileService fileService,
    BackupCrypto? backupCrypto,
    DateTime Function()? clock,
  }) : _deviceStorage = deviceStorage,
       _keyStore = keyStore,
       _keyArchive = keyArchive,
       _files = fileService,
       _crypto = backupCrypto ?? BackupCrypto(),
       _now = clock ?? DateTime.now;

  final DeviceStorageService _deviceStorage;
  final ChannelKeyStore _keyStore;
  final ChannelKeyArchive _keyArchive;
  final BackupFileService _files;
  final BackupCrypto _crypto;
  final DateTime Function() _now;

  @override
  Future<BackupSummary> exportToFile({required String passphrase}) async {
    final deviceId = await _deviceStorage.getDeviceId();
    final deviceToken = await _deviceStorage.getDeviceToken();
    final identity = await _keyStore.loadIdentityKeyPair();
    if (deviceId == null ||
        deviceId.isEmpty ||
        deviceToken == null ||
        deviceToken.isEmpty ||
        identity == null ||
        identity.publicKeyBase64.isEmpty) {
      throw const BackupException(BackupFailure.notRegistered, 'Device is not registered');
    }

    final payload = BackupPayload(
      deviceId: deviceId,
      deviceName: await _deviceStorage.getDeviceName(),
      deviceToken: deviceToken,
      serverUrl: await _deviceStorage.getServerUrl(),
      identityPrivateKey: identity.privateKeyBase64,
      identityPublicKey: identity.publicKeyBase64,
      channelKeys: await _keyArchive.exportChannelKeys(),
      createdAt: _now(),
    );

    final bytes = await _crypto.seal(
      plaintext: jsonEncode(payload.toJson()),
      passphrase: passphrase,
    );
    final fileName = backupFileName(payload.createdAt);
    final saved = await _files.saveFile(fileName: fileName, bytes: bytes);
    if (!saved) throw const BackupException(BackupFailure.cancelled, 'Save cancelled');

    return BackupSummary(
      deviceName: payload.deviceName,
      channelCount: payload.channelCount,
      createdAt: payload.createdAt,
      fileName: fileName,
    );
  }

  @override
  Future<Uint8List?> pickBackupFile() => _files.openFile();

  @override
  Future<BackupSummary> restore({required Uint8List bytes, required String passphrase}) async {
    final plaintext = await _crypto.open(bytes: bytes, passphrase: passphrase);

    final BackupPayload payload;
    try {
      payload = BackupPayload.fromJson(jsonDecode(plaintext) as Map<String, dynamic>);
    } catch (_) {
      throw const BackupException(BackupFailure.invalidFile, 'Payload is not valid JSON');
    }
    if (!payload.isComplete) {
      throw const BackupException(BackupFailure.incompleteBackup, 'Backup has no identity');
    }

    // Thứ tự quan trọng: key material trước, device token SAU CÙNG. Token là
    // "công tắc" khiến Splash coi máy đã đăng ký — app bị kill giữa chừng thì
    // lần mở sau vẫn được mời khôi phục lại, không rơi vào trạng thái nửa vời.
    await _keyArchive.restoreIdentityKeyPair(IdentityKeyPair(
      privateKeyBase64: payload.identityPrivateKey,
      publicKeyBase64: payload.identityPublicKey,
    ));
    await _keyArchive.importChannelKeys(payload.channelKeys);

    await _deviceStorage.saveDeviceId(payload.deviceId);
    final name = payload.deviceName;
    if (name != null && name.trim().isNotEmpty) await _deviceStorage.saveDeviceName(name);
    final serverUrl = payload.serverUrl;
    if (serverUrl != null && serverUrl.trim().isNotEmpty) await _deviceStorage.saveServerUrl(serverUrl);
    await _deviceStorage.saveDeviceToken(payload.deviceToken);

    return BackupSummary(
      deviceName: payload.deviceName,
      channelCount: payload.channelCount,
      createdAt: payload.createdAt,
    );
  }

  /// `sms-navigator-20261022-0415.smsnav` (giờ máy).
  static String backupFileName(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    final local = time.toLocal();
    return 'sms-navigator-${local.year}${two(local.month)}${two(local.day)}'
        '-${two(local.hour)}${two(local.minute)}.${BackupCrypto.fileExtension}';
  }
}
