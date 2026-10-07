import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/models/invite_preview_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/join_channel_repository.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/features/channel_join/join_confirm_page.dart';
import 'package:sms_navigator/features/device/bloc/device_profile_cubit.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeChannelRepository implements ChannelRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceStorageService implements DeviceStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getDeviceId() async => 'dev_123';

  @override
  Future<String?> getDeviceName() async => 'Pixel 8 Pro của Minh';
}

class _FakeJoinChannelRepository implements JoinChannelRepository {
  Completer<InvitePreviewModel>? resolveCompleter;
  InvitePreviewModel? resolveResult;
  Object? resolveError;

  InvitePayload? lastClaimedInvite;
  String? lastClaimedName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<InvitePreviewModel> resolveInvite(InvitePayload invite) async {
    if (resolveCompleter != null) return resolveCompleter!.future;
    if (resolveError != null) throw resolveError!;
    return resolveResult ??
        InvitePreviewModel(
          sessionId: invite.sessionId,
          channelId: 'ch_test',
          channelName: 'Viettel Telecom',
          ownerDeviceName: 'Pixel 8 Pro của Minh',
          expiresAt: DateTime.now().add(const Duration(minutes: 9)),
        );
  }

  @override
  Future<ClaimRequestResultModel> claim({
    required InvitePayload invite,
    required String deviceName,
  }) async {
    lastClaimedInvite = invite;
    lastClaimedName = deviceName;
    return const ClaimRequestResultModel(
      requestId: 'req_123',
      channelId: 'ch_test',
      channelName: 'Viettel Telecom',
      ownerDeviceName: 'Pixel 8 Pro của Minh',
    );
  }
}

void main() {
  late _FakeJoinChannelRepository joinRepository;
  late _FakeChannelRepository channelRepository;
  late _FakeDeviceStorageService deviceStorage;

  final validInviteUrl =
      'smsnavigator://pair?v=4&s=7c90b07f-0524-4f8e-a9d6-58c03507dfb9'
      '&t=0123456789abcdef0123456789abcdef'
      '&u=aHR0cHM6Ly9leGFtcGxlLmNvbQ'
      '&e=${DateTime.now().millisecondsSinceEpoch + 600000}';

  setUp(() {
    joinRepository = _FakeJoinChannelRepository();
    channelRepository = _FakeChannelRepository();
    deviceStorage = _FakeDeviceStorageService();
  });

  Widget buildTestWidget({required String inviteRaw}) {
    return RepositoryProvider<JoinChannelRepository>.value(
      value: joinRepository,
      child: BlocProvider<DeviceProfileCubit>(
        create: (_) => DeviceProfileCubit(
          deviceStorage: deviceStorage,
          channelRepository: channelRepository,
        )..loadDeviceProfile(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: JoinConfirmPage(inviteRaw: inviteRaw),
        ),
      ),
    );
  }

  testWidgets('shows skeleton view while resolving channel', (tester) async {
    joinRepository.resolveCompleter = Completer<InvitePreviewModel>();

    await tester.pumpWidget(buildTestWidget(inviteRaw: validInviteUrl));
    await tester.pump(); // Trigger frame

    expect(find.text('Đang tải thông tin kênh...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays channel and owner when resolve completes', (tester) async {
    joinRepository.resolveResult = InvitePreviewModel(
      sessionId: 'sess_1',
      channelId: 'ch_1',
      channelName: 'Kênh Gia Đình',
      ownerDeviceName: 'Bố Hoàng',
      expiresAt: DateTime.now().add(const Duration(minutes: 9)),
    );

    await tester.pumpWidget(buildTestWidget(inviteRaw: validInviteUrl));
    await tester.pumpAndSettle();

    expect(find.text('Kênh Gia Đình'), findsOneWidget);
    expect(find.text('Chủ kênh: Bố Hoàng'), findsOneWidget);
    expect(find.text('Gửi yêu cầu kết nối'), findsOneWidget);
  });

  testWidgets('pressing Gửi yêu cầu kết nối invokes claim', (tester) async {
    await tester.pumpWidget(buildTestWidget(inviteRaw: validInviteUrl));
    await tester.pumpAndSettle();

    final submitButton = find.text('Gửi yêu cầu kết nối');
    expect(submitButton, findsOneWidget);

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(joinRepository.lastClaimedInvite, isNotNull);
    expect(joinRepository.lastClaimedInvite?.sessionId,
        '7c90b07f-0524-4f8e-a9d6-58c03507dfb9');
  });

  testWidgets('shows error view when resolve fails with general error', (tester) async {
    joinRepository.resolveError = const ApiException(
      'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.',
      statusCode: 410,
      errorCode: 'QR_EXPIRED',
    );

    await tester.pumpWidget(buildTestWidget(inviteRaw: validInviteUrl));
    await tester.pumpAndSettle();

    expect(find.text('Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets('shows error view when invite QR format is invalid', (tester) async {
    await tester.pumpWidget(buildTestWidget(inviteRaw: 'invalid_qr_data'));
    await tester.pumpAndSettle();

    expect(find.text('Mã QR không đúng định dạng. Hãy xin Chủ kênh một mã mời mới.'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });
}
