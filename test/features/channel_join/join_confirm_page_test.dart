import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/invite_preview_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/qr_repository.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/features/channel_join/join_confirm_page.dart';
import 'package:sms_navigator/features/device/bloc/device_profile_cubit.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

import '../qr_entry/fake_qr_repository.dart';

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

void main() {
  const code = 'AbCdEfGhIjKlMnOpQrSt_-';
  late FakeQrRepository qrRepository;

  setUp(() => qrRepository = FakeQrRepository());

  Widget buildTestWidget() {
    final preview = InvitePreviewModel(
      sessionId: '',
      channelId: 'ch_1',
      channelName: 'Kênh Gia Đình',
      ownerDeviceName: 'Bố Hoàng',
      expiresAt: DateTime.now().add(const Duration(minutes: 9)),
    );
    return RepositoryProvider<QrRepository>.value(
      value: qrRepository,
      child: BlocProvider<DeviceProfileCubit>(
        create: (_) => DeviceProfileCubit(
          deviceStorage: _FakeDeviceStorageService(),
          channelRepository: _FakeChannelRepository(),
        )..loadDeviceProfile(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: JoinConfirmPage.fromQr(code: code, preview: preview),
        ),
      ),
    );
  }

  testWidgets('shows the resolved channel and owner straight away', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Kênh Gia Đình'), findsOneWidget);
    expect(find.text('Chủ kênh: Bố Hoàng'), findsOneWidget);
    expect(find.text('Gửi yêu cầu kết nối'), findsOneWidget);
  });

  testWidgets('pressing Gửi yêu cầu kết nối claims with the QR code', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gửi yêu cầu kết nối'));
    await tester.pumpAndSettle();

    expect(qrRepository.claimedCodes, [code]);
  });
}
