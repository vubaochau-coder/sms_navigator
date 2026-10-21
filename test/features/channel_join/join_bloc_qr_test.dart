import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/invite_preview_model.dart';
import 'package:sms_navigator/core/repositories/join_channel_repository.dart';
import 'package:sms_navigator/features/channel_join/bloc/join_bloc.dart';

import '../qr_entry/fake_qr_repository.dart';

/// The v4 repository must not be touched on the opaque-QR path.
class _UntouchedJoinRepository implements JoinChannelRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('v4 path used: ${invocation.memberName}');
}

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
    bloc = JoinBloc(
      repository: _UntouchedJoinRepository(),
      initialDeviceName: 'Galaxy A23',
      qrRepository: qrRepo,
    );
  });

  tearDown(() => bloc.close());

  test('JoinInitializedWithPreview goes straight to ready — no resolve call', () async {
    bloc.add(JoinInitializedWithPreview(preview: preview, code: code));
    await pumpEventQueue();

    expect(bloc.state.phase, JoinPhase.ready);
    expect(bloc.state.channelName, 'Kênh VCB OTP');
    expect(bloc.state.code, code);
  });

  test('submit claims with the code, never with a pairing token', () async {
    bloc.add(JoinInitializedWithPreview(preview: preview, code: code));
    bloc.add(const JoinSubmitted('Galaxy A23'));
    await pumpEventQueue();

    expect(qrRepo.claimedCodes, [code]);
    expect(bloc.state.phase, JoinPhase.claimSuccess);
    expect(bloc.state.requestId, 'req-1');
  });
}
