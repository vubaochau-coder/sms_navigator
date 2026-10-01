import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/paired_device_item.dart';
import 'package:sms_navigator/features/pairing/data/services/pair_management_service.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/paired_receivers_bloc.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/paired_receivers_event.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/paired_senders_bloc.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/paired_senders_event.dart';
import 'package:sms_navigator/features/pairing/presentation/widgets/paired_receivers_body.dart';
import 'package:sms_navigator/features/pairing/presentation/widgets/paired_senders_body.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

Widget _buildTestApp({required Widget body}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: Scaffold(body: body),
  );
}

class _MockPairManagementService implements PairManagementService {
  List<PairedDeviceItem> receiversList = [];
  List<PairedDeviceItem> sendersList = [];

  @override
  Future<List<PairedDeviceItem>> getPairedReceivers({
    CancelToken? cancelToken,
  }) async => receiversList;

  @override
  Future<List<PairedDeviceItem>> getPairedSenders({
    CancelToken? cancelToken,
  }) async => sendersList;
}

void main() {
  group('PairedReceiversBody Widget Tests (Sender Side)', () {
    testWidgets('shows empty state when no receivers are paired', (
      tester,
    ) async {
      final mock = _MockPairManagementService();

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => PairedReceiversBloc(mock)
            ..add(const PairedReceiversLoadEvent()),
          child: _buildTestApp(body: const PairedReceiversBody()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có thiết bị nhận nào'), findsOneWidget);
      expect(find.text('Tạo mã QR ghép đôi'), findsOneWidget);
    });

    testWidgets('renders receiver items', (tester) async {
      final mock = _MockPairManagementService();
      mock.receiversList = [
        PairedDeviceItem(
          pairId: 'pair_123',
          deviceId: 'rec_device_abc',
          deviceName: 'Máy Nhận Malaysia',
          platform: 'android',
          pairedAt: DateTime.fromMillisecondsSinceEpoch(1727620000 * 1000),
        ),
      ];

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => PairedReceiversBloc(mock)
            ..add(const PairedReceiversLoadEvent()),
          child: _buildTestApp(body: const PairedReceiversBody()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Máy Nhận Malaysia'), findsOneWidget);
      expect(find.text('Đang gửi'), findsOneWidget);

      // Toggle feature has been removed for MVP: no Switch anywhere
      expect(find.byType(Switch), findsNothing);
    });
  });

  group('PairedSendersBody Widget Tests (Receiver Side)', () {
    testWidgets('shows empty state when no senders are paired', (tester) async {
      final mock = _MockPairManagementService();

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => PairedSendersBloc(mock)
            ..add(const PairedSendersLoadEvent()),
          child: _buildTestApp(body: const PairedSendersBody()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa kết nối máy gửi nào'), findsOneWidget);
      expect(find.text('Quét mã QR ghép đôi'), findsOneWidget);
    });

    testWidgets(
      'renders sender items with read-only badge and no toggle switch',
      (tester) async {
        final mock = _MockPairManagementService();
        mock.sendersList = [
          PairedDeviceItem(
            pairId: 'pair_456',
            deviceId: 'send_device_xyz',
            deviceName: 'Máy Gửi Việt Nam',
            platform: 'android',
            pairedAt: DateTime.fromMillisecondsSinceEpoch(1727620000 * 1000),
            isSender: true,
          ),
        ];

        await tester.pumpWidget(
          BlocProvider(
            create: (_) => PairedSendersBloc(mock)
              ..add(const PairedSendersLoadEvent()),
            child: _buildTestApp(body: const PairedSendersBody()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Máy Gửi Việt Nam'), findsOneWidget);
        expect(find.text('Đang duy trì gửi'), findsOneWidget);
        expect(
          find.textContaining('Người gửi đang duy trì truyền tin. (Chỉ xem)'),
          findsOneWidget,
        );

        // Toggle feature has been removed for MVP: no interactive Switch
        expect(find.byType(Switch), findsNothing);
      },
    );
  });
}
