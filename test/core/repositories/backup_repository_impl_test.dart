import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/repositories/backup_repository.dart';
import 'package:sms_navigator/core/services/local_storage_service.dart';
import 'package:sms_navigator/core/crypto/backup_crypto.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';
import 'package:sms_navigator/core/repositories/impls/backup_repository_impl.dart';
import 'package:sms_navigator/core/services/backup_file_service.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';

/// Ghi lại thứ tự ghi để kiểm tra "device token sau cùng".
final List<String> _writes = [];

class _DeviceStorage implements DeviceStorageService {
  String? id, name, token, serverUrl;

  @override
  Future<String?> getDeviceId() async => id;
  @override
  Future<String?> getDeviceName() async => name;
  @override
  Future<String?> getDeviceToken() async => token;
  @override
  Future<String?> getServerUrl() async => serverUrl;
  @override
  Future<void> saveDeviceId(String v) async {
    _writes.add('deviceId');
    id = v;
  }

  @override
  Future<void> saveDeviceName(String v) async {
    _writes.add('deviceName');
    name = v;
  }

  @override
  Future<void> saveDeviceToken(String v) async {
    _writes.add('deviceToken');
    token = v;
  }

  @override
  Future<void> saveServerUrl(String v) async {
    _writes.add('serverUrl');
    serverUrl = v;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Keys implements ChannelKeyStore, ChannelKeyArchive {
  IdentityKeyPair? identity;
  final Map<String, Map<int, String>> keys = {};

  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async => identity;
  @override
  Future<Map<String, Map<int, String>>> exportChannelKeys() async =>
      {for (final e in keys.entries) e.key: Map.of(e.value)};
  @override
  Future<void> restoreIdentityKeyPair(IdentityKeyPair keyPair) async {
    _writes.add('identity');
    identity = keyPair;
  }

  @override
  Future<void> importChannelKeys(Map<String, Map<int, String>> imported) async {
    _writes.add('channelKeys');
    imported.forEach((id, epochs) => keys.putIfAbsent(id, () => {}).addAll(epochs));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Files implements BackupFileService {
  Uint8List? saved;
  String? savedName;
  bool cancelSave = false;

  @override
  Future<bool> saveFile({required String fileName, required Uint8List bytes}) async {
    if (cancelSave) return false;
    saved = bytes;
    savedName = fileName;
    return true;
  }

  @override
  Future<Uint8List?> openFile() async => saved;
}

class _Prefs implements LocalStorageService {
  final Map<String, Object> data = {};

  @override
  String? getString(String key) => data[key] as String?;
  @override
  Future<void> setString(String key, String value) async => data[key] = value;
  @override
  bool? getBool(String key) => data[key] as bool?;
  @override
  Future<void> setBool(String key, bool value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
  @override
  Future<void> reload() async {}
}

void main() {
  const passphrase = 'correct horse battery';
  final now = DateTime(2026, 10, 22, 4, 15);
  final crypto = BackupCrypto(iterations: BackupCrypto.minIterations);

  late _DeviceStorage oldDevice;
  late _Keys oldKeys;
  late _Files files;

  BackupRepositoryImpl repoFor(_DeviceStorage storage, _Keys keys, {LocalStorageService? prefs}) => BackupRepositoryImpl(
    deviceStorage: storage,
    keyStore: keys,
    keyArchive: keys,
    fileService: files,
    localStorage: prefs,
    backupCrypto: crypto,
    clock: () => now,
  );

  setUp(() {
    _writes.clear();
    files = _Files();
    oldDevice = _DeviceStorage()
      ..id = 'dev-1'
      ..name = 'Pixel cũ'
      ..token = 'tok-1'
      ..serverUrl = 'https://relay.test';
    oldKeys = _Keys()
      ..identity = const IdentityKeyPair(privateKeyBase64: 'priv', publicKeyBase64: 'pub')
      ..keys.addAll({
        'ch-a': {1: 'a1', 2: 'a2'},
        'ch-b': {3: 'b3'},
      });
  });

  test('export → restore on a fresh install reproduces the same device', () async {
    final summary = await repoFor(oldDevice, oldKeys).exportToFile(passphrase: passphrase);
    expect(summary.channelCount, 2);
    expect(summary.deviceName, 'Pixel cũ');
    expect(files.savedName, 'sms-navigator-20261022-0415.smsnav');

    final newDevice = _DeviceStorage();
    final newKeys = _Keys()
      ..identity = const IdentityKeyPair(privateKeyBase64: 'fresh', publicKeyBase64: 'fresh-pub');
    _writes.clear();

    final restored = await repoFor(newDevice, newKeys).restore(bytes: files.saved!, passphrase: passphrase);

    expect(restored.channelCount, 2);
    expect(newKeys.identity, oldKeys.identity);
    expect(newKeys.keys, oldKeys.keys);
    expect(newDevice.id, 'dev-1');
    expect(newDevice.name, 'Pixel cũ');
    expect(newDevice.token, 'tok-1');
    expect(newDevice.serverUrl, 'https://relay.test');
    // Token là công tắc "đã đăng ký" → phải ghi sau cùng.
    expect(_writes.last, 'deviceToken');
    expect(_writes.indexOf('identity'), lessThan(_writes.indexOf('deviceToken')));
  });

  test('export and restore remember which channels the backup covers (BACKLOG 1.9)', () async {
    final oldPrefs = _Prefs();
    final oldRepo = repoFor(oldDevice, oldKeys, prefs: oldPrefs);
    expect(oldRepo.lastBackupRecord(), isNull);

    await oldRepo.exportToFile(passphrase: passphrase);
    expect(oldRepo.lastBackupRecord(), BackupRecord(at: now, channelIds: const {'ch-a', 'ch-b'}));

    final newPrefs = _Prefs();
    final newRepo = repoFor(_DeviceStorage(), _Keys(), prefs: newPrefs);
    await newRepo.restore(bytes: files.saved!, passphrase: passphrase);
    expect(newRepo.lastBackupRecord()?.channelIds, {'ch-a', 'ch-b'});
  });

  test('a cancelled save records nothing', () async {
    final prefs = _Prefs();
    files.cancelSave = true;
    final repo = repoFor(oldDevice, oldKeys, prefs: prefs);
    await expectLater(repo.exportToFile(passphrase: passphrase), throwsA(isA<BackupException>()));
    expect(repo.lastBackupRecord(), isNull);
  });

  test('wrong passphrase writes nothing', () async {
    await repoFor(oldDevice, oldKeys).exportToFile(passphrase: passphrase);
    final newDevice = _DeviceStorage();
    final newKeys = _Keys();
    _writes.clear();

    await expectLater(
      repoFor(newDevice, newKeys).restore(bytes: files.saved!, passphrase: 'not the passphrase'),
      throwsA(isA<BackupException>().having((e) => e.failure, 'failure', BackupFailure.wrongPassphrase)),
    );
    expect(_writes, isEmpty);
    expect(newDevice.token, isNull);
  });

  test('cancelling the save dialog → cancelled', () async {
    files.cancelSave = true;
    await expectLater(
      repoFor(oldDevice, oldKeys).exportToFile(passphrase: passphrase),
      throwsA(isA<BackupException>().having((e) => e.failure, 'failure', BackupFailure.cancelled)),
    );
  });

  test('unregistered device cannot export', () async {
    oldDevice.token = null;
    await expectLater(
      repoFor(oldDevice, oldKeys).exportToFile(passphrase: passphrase),
      throwsA(isA<BackupException>().having((e) => e.failure, 'failure', BackupFailure.notRegistered)),
    );
    expect(files.saved, isNull);
  });

  test('backupFileName is zero-padded local time', () {
    expect(BackupRepositoryImpl.backupFileName(DateTime(2026, 1, 2, 3, 4)), 'sms-navigator-20260102-0304.smsnav');
  });
}
