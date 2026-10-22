import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/crypto/backup_crypto.dart';

void main() {
  // Số vòng nhỏ nhất file hợp lệ được phép — đủ nhanh cho unit test.
  final crypto = BackupCrypto(iterations: BackupCrypto.minIterations);
  const passphrase = 'correct horse battery';

  Map<String, dynamic> decodeEnvelope(Uint8List bytes) =>
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

  Uint8List encodeEnvelope(Map<String, dynamic> envelope) =>
      Uint8List.fromList(utf8.encode(jsonEncode(envelope)));

  Future<BackupFailure> failureOf(Future<Object?> future) async {
    try {
      await future;
    } on BackupException catch (e) {
      return e.failure;
    }
    fail('expected a BackupException');
  }

  test('seal → open round-trips and the envelope never contains the plaintext', () async {
    const plaintext = '{"identity":{"private_key":"SECRET-KEY"}}';
    final sealed = await crypto.seal(plaintext: plaintext, passphrase: passphrase);

    expect(utf8.decode(sealed), isNot(contains('SECRET-KEY')));
    final envelope = decodeEnvelope(sealed);
    expect(envelope['format'], 'smsnav-backup');
    expect(envelope['version'], 1);
    expect((envelope['kdf'] as Map)['iterations'], BackupCrypto.minIterations);

    expect(await crypto.open(bytes: sealed, passphrase: passphrase), plaintext);
  });

  test('two seals of the same data use fresh salt and nonce', () async {
    final a = decodeEnvelope(await crypto.seal(plaintext: 'x', passphrase: passphrase));
    final b = decodeEnvelope(await crypto.seal(plaintext: 'x', passphrase: passphrase));
    expect((a['kdf'] as Map)['salt'], isNot((b['kdf'] as Map)['salt']));
    expect((a['cipher'] as Map)['nonce'], isNot((b['cipher'] as Map)['nonce']));
  });

  test('wrong passphrase → wrongPassphrase', () async {
    final sealed = await crypto.seal(plaintext: 'x', passphrase: passphrase);
    expect(await failureOf(crypto.open(bytes: sealed, passphrase: 'wrong passphrase!')), BackupFailure.wrongPassphrase);
  });

  test('tampered ciphertext → wrongPassphrase (GCM tag)', () async {
    final envelope = decodeEnvelope(await crypto.seal(plaintext: 'hello world', passphrase: passphrase));
    final ct = base64Decode(envelope['ciphertext'] as String);
    ct[0] ^= 0x01;
    envelope['ciphertext'] = base64Encode(ct);
    expect(
      await failureOf(crypto.open(bytes: encodeEnvelope(envelope), passphrase: passphrase)),
      BackupFailure.wrongPassphrase,
    );
  });

  test('not a backup → invalidFile', () async {
    expect(
      await failureOf(crypto.open(bytes: Uint8List.fromList(utf8.encode('hello')), passphrase: passphrase)),
      BackupFailure.invalidFile,
    );
    expect(
      await failureOf(crypto.open(bytes: encodeEnvelope({'format': 'other', 'version': 1}), passphrase: passphrase)),
      BackupFailure.invalidFile,
    );
  });

  test('newer format version → unsupportedVersion', () async {
    final envelope = decodeEnvelope(await crypto.seal(plaintext: 'x', passphrase: passphrase));
    envelope['version'] = 99;
    expect(
      await failureOf(crypto.open(bytes: encodeEnvelope(envelope), passphrase: passphrase)),
      BackupFailure.unsupportedVersion,
    );
  });

  test('absurd iteration counts are rejected before running the KDF', () async {
    final envelope = decodeEnvelope(await crypto.seal(plaintext: 'x', passphrase: passphrase));
    (envelope['kdf'] as Map)['iterations'] = 1000000000;
    expect(
      await failureOf(crypto.open(bytes: encodeEnvelope(envelope), passphrase: passphrase)),
      BackupFailure.invalidFile,
    );
    (envelope['kdf'] as Map)['iterations'] = 10;
    expect(
      await failureOf(crypto.open(bytes: encodeEnvelope(envelope), passphrase: passphrase)),
      BackupFailure.invalidFile,
    );
  });

  test('header version is bound into the AAD', () async {
    // Hạ version của file v1 xuống 0 thì bị chặn ngay; nâng/hạ trong tương lai
    // sẽ làm hỏng tag vì AAD = "smsnav-backup|v1".
    final envelope = decodeEnvelope(await crypto.seal(plaintext: 'x', passphrase: passphrase));
    envelope['version'] = 0;
    expect(
      await failureOf(crypto.open(bytes: encodeEnvelope(envelope), passphrase: passphrase)),
      BackupFailure.invalidFile,
    );
  });
}
