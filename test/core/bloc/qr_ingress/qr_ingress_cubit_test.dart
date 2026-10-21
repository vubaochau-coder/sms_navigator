import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/services/deep_link_service.dart';
import 'package:sms_navigator/core/utils/qr_error_messages.dart';
import 'package:sms_navigator/core/utils/qr_link_parser.dart';
import 'package:sms_navigator/core/bloc/qr_ingress/qr_ingress_cubit.dart';

import '../../../features/qr_entry/fake_qr_repository.dart';

class _FakeDeepLinks implements DeepLinkService {
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => controller.stream;
}

void main() {
  const code = 'AbCdEfGhIjKlMnOpQrSt_-';
  const host = 'sms-relay.hirusakunasaga.workers.dev';

  late FakeQrRepository repo;
  late _FakeDeepLinks deepLinks;
  late DateTime now;
  late QrIngressCubit cubit;

  setUp(() {
    repo = FakeQrRepository();
    deepLinks = _FakeDeepLinks();
    now = DateTime(2026, 10, 21, 10);
    cubit = QrIngressCubit(repository: repo, deepLinks: deepLinks, clock: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await deepLinks.controller.close();
  });

  test('a deeplink becomes a pending code that is consumed exactly once', () async {
    deepLinks.controller.add(Uri.parse('https://$host/qr/$code'));
    await pumpEventQueue();

    expect(cubit.state.pending, const OpaqueQrLink(code));
    expect(cubit.consume(), const OpaqueQrLink(code));
    expect(cubit.consume(), isNull);
    expect(cubit.state.pending, isNull);
  });

  test('a link to a foreign host is rejected with a toast message', () async {
    await cubit.submit('https://evil.example/qr/$code');

    expect(cubit.state.pending, isNull);
    expect(cubit.state.rejectionSeq, 1);
    expect(cubit.state.rejectionMessage, QrErrorMessages.unsupportedFormat);
  });

  test('the same link re-delivered by the OS within the window is ignored', () async {
    await cubit.submit('smsnavigator://qr?code=$code');
    cubit.consume();
    await cubit.submit('smsnavigator://qr?code=$code');

    expect(cubit.state.pending, isNull);
    expect(cubit.state.pendingSeq, 1);

    now = now.add(const Duration(seconds: 5));
    await cubit.submit('smsnavigator://qr?code=$code');
    expect(cubit.state.pendingSeq, 2);
  });

  test('legacy v4 invites are passed through for the transition', () async {
    const v4 = 'smsnavigator://pair?v=4&s=session_123&t=token_abc&u=aHR0cHM6Ly9hcGkuaW8&e=1790999999999';
    await cubit.submit(v4);
    expect(cubit.state.pending, const LegacyInviteLink(v4));
  });
}
