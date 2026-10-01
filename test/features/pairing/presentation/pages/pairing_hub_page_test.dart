import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/paired_device_item.dart';
import 'package:sms_navigator/features/pairing/data/services/pair_management_service.dart';
import 'package:sms_navigator/features/pairing/presentation/pages/pairing_hub_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _TrackingPairManagementService implements PairManagementService {
  int getReceiversCallCount = 0;
  int getSendersCallCount = 0;

  List<PairedDeviceItem> receivers = [
    PairedDeviceItem(
      pairId: 'rec_1',
      deviceId: 'dev_rec_1',
      deviceName: 'Receiver A',
      platform: 'android',
      pairedAt: DateTime.fromMillisecondsSinceEpoch(1727620000 * 1000),
    ),
  ];

  List<PairedDeviceItem> senders = [
    PairedDeviceItem(
      pairId: 'send_1',
      deviceId: 'dev_send_1',
      deviceName: 'Sender B',
      platform: 'android',
      pairedAt: DateTime.fromMillisecondsSinceEpoch(1727620000 * 1000),
      isSender: true,
    ),
  ];

  @override
  Future<List<PairedDeviceItem>> getPairedReceivers({
    CancelToken? cancelToken,
  }) async {
    getReceiversCallCount++;
    return receivers;
  }

  @override
  Future<List<PairedDeviceItem>> getPairedSenders({
    CancelToken? cancelToken,
  }) async {
    getSendersCallCount++;
    return senders;
  }
}

void main() {
  testWidgets(
    'PairingHubPage initializes tabs lazily, keeps state alive across tabs, and supports pull-to-refresh',
    (tester) async {
      final mock = _TrackingPairManagementService();

      await tester.pumpWidget(
        RepositoryProvider<PairManagementService>.value(
          value: mock,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: PairingHubPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial load: Only Receivers tab was rendered and loaded
      expect(mock.getReceiversCallCount, equals(1));
      expect(find.text('Receiver A'), findsOneWidget);

      // 2. Switch to Senders tab
      await tester.tap(find.text('Máy gửi'));
      await tester.pumpAndSettle();

      // Senders tab loaded lazily on first view
      expect(mock.getSendersCallCount, equals(1));
      expect(find.text('Sender B'), findsOneWidget);

      // 3. Switch back to Receivers tab
      await tester.tap(find.text('Máy nhận'));
      await tester.pumpAndSettle();

      // Because of keep-alive, getReceivers was NOT called again
      expect(mock.getReceiversCallCount, equals(1));
      expect(find.text('Receiver A'), findsOneWidget);

      // 4. Test Pull-to-refresh on Receivers tab
      await tester.fling(
        find.text('Receiver A'),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      // Pull-to-refresh triggered explicit reload for Receivers
      expect(mock.getReceiversCallCount, equals(2));
      expect(mock.getSendersCallCount, equals(1));
    },
  );
}
