import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/models/invite_preview_model.dart';
import 'package:sms_navigator/features/channel_join/bloc/join_bloc.dart';

import '../qr_entry/fake_qr_repository.dart';

void main() {
  const code = 'AbCdEfGhIjKlMnOpQrSt_-';
  final preview = InvitePreviewModel(
    sessionId: '',
    channelId: 'ch-1',
    channelName: 'Kênh VCB OTP',
    ownerDeviceName: 'Pixel 7 Pro',
    expiresAt: DateTime(2026, 10, 21, 10, 10),
  );

  late FakeQrRepository qrRepo;
  late JoinBloc bloc;

  setUp(() {
    qrRepo = FakeQrRepository();
    bloc = JoinBloc(qrRepository: qrRepo, initialDeviceName: 'Galaxy A23');
  });

  tearDown(() => bloc.close());

  test('initial state has JoinPhase.initial and the initial device name', () {
    expect(bloc.state.phase, JoinPhase.initial);
    expect(bloc.state.deviceName, 'Galaxy A23');
  });

  test(
    'JoinInitializedWithPreview goes straight to ready — no resolve call',
    () async {
      bloc.add(JoinInitializedWithPreview(preview: preview, code: code));
      await pumpEventQueue();

      expect(bloc.state.phase, JoinPhase.ready);
      expect(bloc.state.channelName, 'Kênh VCB OTP');
      expect(bloc.state.code, code);
    },
  );

  test('submit claims with the code and the chosen device name', () async {
    bloc.add(JoinInitializedWithPreview(preview: preview, code: code));
    bloc.add(const JoinSubmitted('Galaxy A23'));
    await pumpEventQueue();

    expect(qrRepo.claimedCodes, [code]);
    expect(qrRepo.claimedNames, ['Galaxy A23']);
    expect(bloc.state.phase, JoinPhase.claimSuccess);
    expect(bloc.state.requestId, 'req-1');
  });

  test('submit before a preview arrived does nothing', () async {
    bloc.add(const JoinSubmitted('Galaxy A23'));
    await pumpEventQueue();

    expect(qrRepo.claimedCodes, isEmpty);
    expect(bloc.state.phase, JoinPhase.initial);
  });

  test('claim failure → claimFailed with the mapped message', () async {
    qrRepo.claimError = const ApiException(
      'Already used',
      statusCode: 409,
      errorCode: 'QR_ALREADY_USED',
    );
    bloc.add(JoinInitializedWithPreview(preview: preview, code: code));
    await pumpEventQueue();

    expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<JoinState>((s) => s.phase == JoinPhase.claiming),
        predicate<JoinState>(
          (s) =>
              s.phase == JoinPhase.claimFailed &&
              s.errorCode == 'QR_ALREADY_USED' &&
              s.errorMessage ==
                  'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.',
        ),
      ]),
    );
    bloc.add(const JoinSubmitted('Galaxy A23'));
  });
}
