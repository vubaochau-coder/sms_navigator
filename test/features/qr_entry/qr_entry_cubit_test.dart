import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/models/invite_preview_model.dart';
import 'package:sms_navigator/core/models/qr_resolution.dart';
import 'package:sms_navigator/core/utils/qr_error_messages.dart';
import 'package:sms_navigator/features/qr_entry/bloc/qr_entry_cubit.dart';

import 'fake_qr_repository.dart';

void main() {
  const code = 'AbCdEfGhIjKlMnOpQrSt_-';
  late FakeQrRepository repo;
  late QrEntryCubit cubit;

  setUp(() {
    repo = FakeQrRepository();
    cubit = QrEntryCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  test('PAIRING resolution → resolved with the preview', () async {
    final preview = InvitePreviewModel(
      sessionId: '',
      channelId: 'ch-1',
      channelName: 'Kênh VCB OTP',
      ownerDeviceName: 'Pixel 7 Pro',
      expiresAt: DateTime(2026, 10, 21, 10, 10),
    );
    repo.resolution = PairingQrResolution(code: code, preview: preview);

    await cubit.resolve(code);

    expect(cubit.state.phase, QrEntryPhase.resolved);
    expect(cubit.state.resolution, PairingQrResolution(code: code, preview: preview));
  });

  test('unknown QR type → asks the user to update the app', () async {
    repo.resolution = const UnsupportedQrResolution('BACKUP');
    await cubit.resolve(code);

    expect(cubit.state.phase, QrEntryPhase.failed);
    expect(cubit.state.errorMessage, QrErrorMessages.updateRequired);
  });

  test('server error codes map to Vietnamese messages', () async {
    repo.resolveError = const ApiException('gone', statusCode: 410, errorCode: 'QR_EXPIRED');
    await cubit.resolve(code);

    expect(cubit.state.phase, QrEntryPhase.failed);
    expect(cubit.state.errorCode, 'QR_EXPIRED');
    expect(cubit.state.errorMessage, contains('hết hạn'));
  });

  test('REQUEST_ALREADY_PENDING is flagged so the page can just pop', () async {
    repo.resolveError = const ApiException('pending', statusCode: 409, errorCode: 'REQUEST_ALREADY_PENDING');
    await cubit.resolve(code);
    expect(cubit.state.isAlreadyPending, isTrue);
  });
}
