
import 'package:flutter/services.dart';

import '../../crypto/backup_crypto.dart';
import '../backup_file_service.dart';

/// Native: `BackupFileChannel.kt` (ACTION_CREATE_DOCUMENT / ACTION_OPEN_DOCUMENT).
class BackupFileServiceImpl implements BackupFileService {
  BackupFileServiceImpl({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'com.example.sms_navigator/backup_file';

  final MethodChannel _channel;

  @override
  Future<bool> saveFile({required String fileName, required Uint8List bytes}) async {
    try {
      final saved = await _channel.invokeMethod<bool>('saveFile', <String, Object>{
        'fileName': fileName,
        'bytes': bytes,
      });
      return saved ?? false;
    } on PlatformException catch (e) {
      throw BackupException(BackupFailure.storage, e.message ?? e.code);
    } on MissingPluginException {
      throw const BackupException(BackupFailure.storage, 'File picker unavailable');
    }
  }

  @override
  Future<Uint8List?> openFile() async {
    try {
      return await _channel.invokeMethod<Uint8List>('openFile');
    } on PlatformException catch (e) {
      throw BackupException(BackupFailure.storage, e.message ?? e.code);
    } on MissingPluginException {
      throw const BackupException(BackupFailure.storage, 'File picker unavailable');
    }
  }
}
