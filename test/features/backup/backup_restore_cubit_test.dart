import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/crypto/backup_crypto.dart';
import 'package:sms_navigator/core/repositories/backup_repository.dart';
import 'package:sms_navigator/features/backup/bloc/backup_restore_cubit.dart';

class _Repo implements BackupRepository {
  Uint8List? pickResult;
  Object? pickError;
  Object? restoreError;
  String? lastPassphrase;

  @override
  Future<Uint8List?> pickBackupFile() async {
    if (pickError != null) throw pickError!;
    return pickResult;
  }

  @override
  Future<BackupSummary> restore({required Uint8List bytes, required String passphrase}) async {
    lastPassphrase = passphrase;
    if (restoreError != null) throw restoreError!;
    return BackupSummary(channelCount: 2, createdAt: DateTime(2026, 10, 22));
  }

  @override
  Future<BackupSummary> exportToFile({required String passphrase}) => throw UnimplementedError();
}

void main() {
  late _Repo repo;
  late BackupRestoreCubit cubit;
  final file = Uint8List.fromList([1, 2, 3]);

  setUp(() {
    repo = _Repo();
    cubit = BackupRestoreCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  test('cancelled pick stays idle', () async {
    await cubit.pickFile();
    expect(cubit.state.status, BackupRestoreStatus.idle);
    expect(cubit.state.hasFile, isFalse);
  });

  test('picked file → fileSelected; cancelling a second pick keeps the first file', () async {
    repo.pickResult = file;
    await cubit.pickFile();
    expect(cubit.state.status, BackupRestoreStatus.fileSelected);

    repo.pickResult = null;
    await cubit.pickFile();
    expect(cubit.state.fileBytes, file);
    expect(cubit.state.status, BackupRestoreStatus.fileSelected);
  });

  test('wrong passphrase keeps the file so the user can retype', () async {
    repo.pickResult = file;
    await cubit.pickFile();
    repo.restoreError = const BackupException(BackupFailure.wrongPassphrase);

    await cubit.restore('nope');

    expect(cubit.state.status, BackupRestoreStatus.fileSelected);
    expect(cubit.state.failure, BackupFailure.wrongPassphrase);
    expect(cubit.state.fileBytes, file);
  });

  test('success drops the file bytes and exposes the summary', () async {
    repo.pickResult = file;
    await cubit.pickFile();

    await cubit.restore('correct horse battery');

    expect(repo.lastPassphrase, 'correct horse battery');
    expect(cubit.state.status, BackupRestoreStatus.success);
    expect(cubit.state.summary?.channelCount, 2);
    expect(cubit.state.fileBytes, isNull);
  });

  test('restore without a file is a no-op', () async {
    await cubit.restore('x');
    expect(cubit.state.status, BackupRestoreStatus.idle);
    expect(repo.lastPassphrase, isNull);
  });

  test('picker failure surfaces as storage error', () async {
    repo.pickError = const BackupException(BackupFailure.storage);
    await cubit.pickFile();
    expect(cubit.state.failure, BackupFailure.storage);
    expect(cubit.state.status, BackupRestoreStatus.idle);
  });
}
