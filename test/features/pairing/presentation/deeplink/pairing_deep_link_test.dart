import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:sms_navigator/core/services/deep_link_service.dart';
import 'package:sms_navigator/core/utils/dialog_utils.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';
import 'package:sms_navigator/features/pairing/data/models/sender_link_status.dart';
import 'package:sms_navigator/features/pairing/data/repositories/pairing_repository.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/pairing_bloc.dart';
import 'package:sms_navigator/features/pairing/presentation/deeplink/pairing_deep_link_listener.dart';
import 'package:sms_navigator/features/pairing/presentation/pages/pairing_deep_link_confirm_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakePairingRepository implements PairingRepository {
  _FakePairingRepository({required this.onSubmitQr});

  final bool Function(String qrData) onSubmitQr;

  final submittedQr = <String>[];

  @override
  Future<PairingPayloadModel> createSenderPairingSession() {
    throw UnimplementedError();
  }

  @override
  Future<bool> applySenderPairing(PairingPayloadModel payload) async => true;

  @override
  Future<SenderLinkStatus> checkSenderPairingLink(
    PairingPayloadModel payload,
  ) async => SenderLinkStatus.waiting;

  @override
  Future<bool> submitReceiverPairingQr(String qrData) async {
    submittedQr.add(qrData);
    return onSubmitQr(qrData);
  }

  @override
  Future<bool> submitReceiverPairingCode(String code) =>
      submitReceiverPairingQr(code);

  @override
  Future<PairingPayloadModel?> checkReceiverPairingStatus() async => null;

  @override
  Future<bool> disconnectReceiver() async => true;

  @override
  Future<void> exportPairingQr(PairingPayloadModel payload) async {}
}

/// DeepLinkService giả: không đụng vào platform channel, phát URI từ
/// [controller] để kiểm tra hành vi của listener.
class _FakeDeepLinkService extends DeepLinkService {
  _FakeDeepLinkService() : super(appLinks: AppLinks());

  final StreamController<Uri> controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get uriStream => controller.stream;
}

final _validPairingUri = Uri.parse(
  'smsnavigator://pair?v=3&k=pairkey1234567890&a=c2VuZGVyX3B1Yl9iYXNlNjRfMzJfYnl0ZXM%3D&e=9999999999999',
);

void main() {
  /// Toast của bloc (3s tự hủy) cần được pump hết để không còn pending timer.
  Future<void> flushToasts(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
  }

  testWidgets(
    'pairing deeplink opens the confirm page and submits the payload',
    (tester) async {
      final repository = _FakePairingRepository(onSubmitQr: (_) => true);
      final bloc = PairingBloc(repository: repository);
      final deepLinkService = _FakeDeepLinkService();

      await tester.pumpWidget(
        ToastificationWrapper(
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<DeepLinkService>.value(value: deepLinkService),
            ],
            child: BlocProvider<PairingBloc>.value(
              value: bloc,
              child: MaterialApp(
                navigatorKey: DialogUtils.navigatorKey,
                locale: const Locale('vi'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: PairingDeepLinkListener(
                  child: const Scaffold(body: Text('home')),
                ),
              ),
            ),
          ),
        ),
      );

      deepLinkService.controller.add(_validPairingUri);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PairingDeepLinkConfirmPage), findsOneWidget);
      expect(repository.submittedQr, [_validPairingUri.toString()]);
      // Payload đã được derive và confirm thành công
      expect(find.text('Đã ghép nối thành công'), findsOneWidget);
      expect(find.text('Hoàn tất'), findsOneWidget);

      await flushToasts(tester);
      unawaited(bloc.close());
    },
  );

  testWidgets('foreign deep links are ignored', (tester) async {
    final repository = _FakePairingRepository(onSubmitQr: (_) => true);
    final bloc = PairingBloc(repository: repository);
    final deepLinkService = _FakeDeepLinkService();

    await tester.pumpWidget(
      ToastificationWrapper(
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<DeepLinkService>.value(value: deepLinkService),
          ],
          child: BlocProvider<PairingBloc>.value(
            value: bloc,
            child: MaterialApp(
              navigatorKey: DialogUtils.navigatorKey,
              locale: const Locale('vi'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: PairingDeepLinkListener(
                child: const Scaffold(body: Text('home')),
              ),
            ),
          ),
        ),
      ),
    );

    deepLinkService.controller.add(Uri.parse('https://example.com/some/path'));
    deepLinkService.controller.add(
      Uri.parse('smsnavigator://other?v=3&k=key'),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PairingDeepLinkConfirmPage), findsNothing);
    expect(repository.submittedQr, isEmpty);

    await flushToasts(tester);
    unawaited(bloc.close());
  });

  testWidgets(
    'confirm page shows error state and closes when pairing fails',
    (tester) async {
      final repository = _FakePairingRepository(onSubmitQr: (_) => false);
      final bloc = PairingBloc(repository: repository);

      await tester.pumpWidget(
        ToastificationWrapper(
          child: BlocProvider<PairingBloc>.value(
            value: bloc,
            child: MaterialApp(
              navigatorKey: DialogUtils.navigatorKey,
              locale: const Locale('vi'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const PairingDeepLinkConfirmPage(qrData: 'smsnavigator://pair?v=3&k=key&a=pub&e=1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.submittedQr, ['smsnavigator://pair?v=3&k=key&a=pub&e=1']);
      expect(find.text('Ghép nối không thành công'), findsOneWidget);
      // Bloc toast + trang hiển thị cùng một thông báo lỗi
      expect(
        find.text('Mã QR không hợp lệ hoặc đã hết hạn.'),
        findsNWidgets(2),
      );

      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.byType(PairingDeepLinkConfirmPage), findsNothing);

      await flushToasts(tester);
      unawaited(bloc.close());
    },
  );
}
