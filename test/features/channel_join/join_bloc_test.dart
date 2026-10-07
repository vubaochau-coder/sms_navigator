import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/models/invite_preview_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/core/repositories/join_channel_repository.dart';
import 'package:sms_navigator/features/channel_join/bloc/join_bloc.dart';

class _FakeJoinChannelRepository implements JoinChannelRepository {
  InvitePreviewModel? resolveResult;
  Object? resolveError;
  ClaimRequestResultModel? claimResult;
  Object? claimError;

  InvitePayload? lastResolvedInvite;
  InvitePayload? lastClaimedInvite;
  String? lastClaimedName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<InvitePreviewModel> resolveInvite(InvitePayload invite) async {
    lastResolvedInvite = invite;
    if (resolveError != null) throw resolveError!;
    return resolveResult ??
        InvitePreviewModel(
          sessionId: invite.sessionId,
          channelId: 'ch_test',
          channelName: 'Kênh Test',
          ownerDeviceName: 'Pixel Owner',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
  }

  @override
  Future<ClaimRequestResultModel> claim({
    required InvitePayload invite,
    required String deviceName,
  }) async {
    lastClaimedInvite = invite;
    lastClaimedName = deviceName;
    if (claimError != null) throw claimError!;
    return claimResult ??
        const ClaimRequestResultModel(
          requestId: 'req_123',
          channelId: 'ch_test',
          channelName: 'Kênh Test',
          ownerDeviceName: 'Pixel Owner',
        );
  }
}

void main() {
  group('JoinBloc Unit Tests', () {
    late _FakeJoinChannelRepository repository;
    late JoinBloc bloc;

    final testInvite = InvitePayload(
      sessionId: 'sess_123',
      pairingToken: 'token_abc',
      serverBaseUrl: 'https://test.com',
      expiryEpochMs: DateTime.now().millisecondsSinceEpoch + 600000,
    );

    setUp(() {
      repository = _FakeJoinChannelRepository();
      bloc = JoinBloc(
        repository: repository,
        initialDeviceName: 'Thiết bị của tôi',
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has JoinPhase.initial and initial device name', () {
      expect(bloc.state.phase, JoinPhase.initial);
      expect(bloc.state.deviceName, 'Thiết bị của tôi');
      expect(bloc.state.preview, isNull);
    });

    test('resolves session successfully -> emits resolving then ready with preview', () async {
      final preview = InvitePreviewModel(
        sessionId: 'sess_123',
        channelId: 'ch_456',
        channelName: 'Kênh Alpha',
        ownerDeviceName: 'Owner Bob',
        expiresAt: DateTime.now().add(const Duration(minutes: 9)),
      );
      repository.resolveResult = preview;

      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<JoinState>((s) => s.phase == JoinPhase.resolving && s.invite == testInvite),
          predicate<JoinState>((s) =>
              s.phase == JoinPhase.ready &&
              s.preview == preview &&
              s.channelName == 'Kênh Alpha' &&
              s.ownerDeviceName == 'Owner Bob'),
        ]),
      );

      bloc.add(JoinResolveStarted(testInvite));
    });

    test('resolve fails with REQUEST_ALREADY_PENDING -> emits resolveFailed with code', () async {
      repository.resolveError = const ApiException(
        'Request already pending',
        statusCode: 409,
        errorCode: 'REQUEST_ALREADY_PENDING',
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<JoinState>((s) => s.phase == JoinPhase.resolving),
          predicate<JoinState>((s) =>
              s.phase == JoinPhase.resolveFailed &&
              s.isAlreadyPending &&
              s.errorMessage == 'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.'),
        ]),
      );

      bloc.add(JoinResolveStarted(testInvite));
    });

    test('resolve fails with ALREADY_MEMBER -> emits resolveFailed with message', () async {
      repository.resolveError = const ApiException(
        'Already member',
        statusCode: 409,
        errorCode: 'ALREADY_MEMBER',
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<JoinState>((s) => s.phase == JoinPhase.resolving),
          predicate<JoinState>((s) =>
              s.phase == JoinPhase.resolveFailed &&
              s.errorMessage == 'Thiết bị của bạn đã là thành viên của kênh này.'),
        ]),
      );

      bloc.add(JoinResolveStarted(testInvite));
    });

    test('resolve fails with QR_EXPIRED -> emits resolveFailed with expired message', () async {
      repository.resolveError = const ApiException(
        'QR expired',
        statusCode: 410,
        errorCode: 'QR_EXPIRED',
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<JoinState>((s) => s.phase == JoinPhase.resolving),
          predicate<JoinState>((s) =>
              s.phase == JoinPhase.resolveFailed &&
              s.errorMessage == 'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.'),
        ]),
      );

      bloc.add(JoinResolveStarted(testInvite));
    });

    test('claims successfully -> emits claiming then claimSuccess', () async {
      // First resolve to set invite
      bloc.add(JoinResolveStarted(testInvite));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<JoinState>((s) => s.phase == JoinPhase.claiming && s.deviceName == 'Galaxy S23'),
          predicate<JoinState>((s) => s.phase == JoinPhase.claimSuccess && s.requestId == 'req_123'),
        ]),
      );

      bloc.add(const JoinSubmitted('Galaxy S23'));
    });

    test('claim fails -> emits claimFailed with error message', () async {
      bloc.add(JoinResolveStarted(testInvite));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      repository.claimError = const ApiException(
        'Already used',
        statusCode: 409,
        errorCode: 'QR_ALREADY_USED',
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<JoinState>((s) => s.phase == JoinPhase.claiming),
          predicate<JoinState>((s) =>
              s.phase == JoinPhase.claimFailed &&
              s.errorMessage == 'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.'),
        ]),
      );

      bloc.add(const JoinSubmitted('Galaxy S23'));
    });
  });
}
