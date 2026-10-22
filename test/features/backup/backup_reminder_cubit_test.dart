import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/repositories/backup_repository.dart';
import 'package:sms_navigator/core/services/local_storage_service.dart';
import 'package:sms_navigator/features/backup/bloc/backup_reminder_cubit.dart';

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

class _Backups implements BackupRepository {
  BackupRecord? record;

  @override
  BackupRecord? lastBackupRecord() => record;
  @override
  Future<BackupSummary> exportToFile({required String passphrase}) => throw UnimplementedError();
  @override
  Future<Uint8List?> pickBackupFile() => throw UnimplementedError();
  @override
  Future<BackupSummary> restore({required Uint8List bytes, required String passphrase}) => throw UnimplementedError();
}

void main() {
  late _Prefs prefs;
  late _Backups backups;
  late DateTime now;
  late BackupReminderCubit cubit;

  setUp(() {
    prefs = _Prefs();
    backups = _Backups();
    now = DateTime(2026, 10, 22, 9);
    cubit = BackupReminderCubit(backupRepository: backups, localStorage: prefs, clock: () => now);
  });

  tearDown(() => cubit.close());

  test('no channels → no reminder', () {
    cubit.update(const []);
    expect(cubit.state, isFalse);
  });

  test('channels but never backed up → reminder', () {
    cubit.update(['ch-a']);
    expect(cubit.state, isTrue);
  });

  test('a backup covering every channel hides it; a newer channel brings it back', () {
    backups.record = BackupRecord(at: now, channelIds: const {'ch-a', 'ch-b'});
    cubit.update(['ch-a', 'ch-b']);
    expect(cubit.state, isFalse);

    cubit.update(['ch-a', 'ch-b', 'ch-new']);
    expect(cubit.state, isTrue);
  });

  test('"Để sau" snoozes for 3 days', () async {
    cubit.update(['ch-a']);
    await cubit.snooze();
    expect(cubit.state, isFalse);

    now = now.add(const Duration(days: 2));
    cubit.recheck();
    expect(cubit.state, isFalse);

    now = now.add(const Duration(days: 1, minutes: 1));
    cubit.recheck();
    expect(cubit.state, isTrue);
  });

  test('without storage (tests / previews) it never shows', () {
    final silent = BackupReminderCubit();
    silent.update(['ch-a']);
    expect(silent.state, isFalse);
    silent.close();
  });

  test('BackupRecord JSON round-trips and rejects junk', () {
    final record = BackupRecord(at: DateTime.utc(2026, 10, 22), channelIds: const {'a', 'b'});
    expect(BackupRecord.fromJson(record.toJson()), record);
    expect(BackupRecord.fromJson('nope'), isNull);
    expect(BackupRecord.fromJson({'at': 'x', 'channels': []}), isNull);
  });
}
