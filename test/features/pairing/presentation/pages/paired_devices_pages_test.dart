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

class _MockPairManagementService implements PairManagementService {
  List<PairedDeviceItem> receiversList = [];
  List<PairedDeviceItem> sendersList = [];
  bool toggleCalled = false;
  String? toggledPairId;
  bool? toggledActiveState;

  @override
  Future<List<PairedDeviceItem>> getPairedReceivers({
    CancelToken? cancelToken,
  }) async => receiversList;

  @override
  Future<List<PairedDeviceItem>> getPairedSenders({
    CancelToken? cancelToken,
  }) async => sendersList;

  @override
  Future<bool> togglePairActive({
    required String pairId,
    required bool isActive,
    CancelToken? cancelToken,
  }) async {
    toggleCalled = true;
    toggledPairId = pairId;
    toggledActiveState = isActive;
    final idx = receiversList.indexWhere((e) => e.pairId == pairId);
    if (idx != -1) {
      receiversList[idx] = receiversList[idx].copyWith(isActive: isActive);
    }
    return true;
  }

  @override
  Future<bool> revokePair(String pairId, {CancelToken? cancelToken}) async {
    receiversList.removeWhere((e) => e.pairId == pairId);
    sendersList.removeWhere((e) => e.pairId == pairId);
    return true;
  }
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
          child: const MaterialApp(home: Scaffold(body: PairedReceiversBody())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có thiết bị nhận nào'), findsOneWidget);
      expect(find.text('Tạo mã QR ghép đôi'), findsOneWidget);
    });

    testWidgets(
      'renders receiver items with toggle switch and handles toggle',
      (tester) async {
        final mock = _MockPairManagementService();
        mock.receiversList = [
          const PairedDeviceItem(
            pairId: 'pair_123',
            deviceId: 'rec_device_abc',
            deviceName: 'Máy Nhận Malaysia',
            platform: 'android',
            isActive: true,
            pairedAt: 1727620000,
          ),
        ];

        await tester.pumpWidget(
          BlocProvider(
            create: (_) => PairedReceiversBloc(mock)
              ..add(const PairedReceiversLoadEvent()),
            child: const MaterialApp(home: Scaffold(body: PairedReceiversBody())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Máy Nhận Malaysia'), findsOneWidget);
        expect(find.text('Đang gửi'), findsOneWidget);
        expect(find.text('Cho phép gửi OTP'), findsOneWidget);

        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget);

        // Tap the switch to pause forwarding
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(mock.toggleCalled, isTrue);
        expect(mock.toggledPairId, 'pair_123');
        expect(mock.toggledActiveState, isFalse);
        expect(find.text('Đã tạm dừng'), findsOneWidget);
      },
    );
  });

  group('PairedSendersBody Widget Tests (Receiver Side)', () {
    testWidgets('shows empty state when no senders are paired', (tester) async {
      final mock = _MockPairManagementService();

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => PairedSendersBloc(mock)
            ..add(const PairedSendersLoadEvent()),
          child: const MaterialApp(home: Scaffold(body: PairedSendersBody())),
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
          const PairedDeviceItem(
            pairId: 'pair_456',
            deviceId: 'send_device_xyz',
            deviceName: 'Máy Gửi Việt Nam',
            platform: 'android',
            isActive: true,
            pairedAt: 1727620000,
            isSender: true,
          ),
        ];

        await tester.pumpWidget(
          BlocProvider(
            create: (_) => PairedSendersBloc(mock)
              ..add(const PairedSendersLoadEvent()),
            child: const MaterialApp(home: Scaffold(body: PairedSendersBody())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Máy Gửi Việt Nam'), findsOneWidget);
        expect(find.text('Đang duy trì gửi'), findsOneWidget);
        expect(
          find.textContaining('Người gửi đang duy trì truyền tin. (Chỉ xem)'),
          findsOneWidget,
        );

        // On receiver side, there must NOT be any interactive toggle Switch
        expect(find.byType(Switch), findsNothing);
      },
    );

    testWidgets(
      'renders paused status clearly for receiver when sender paused relay',
      (tester) async {
        final mock = _MockPairManagementService();
        mock.sendersList = [
          const PairedDeviceItem(
            pairId: 'pair_789',
            deviceId: 'send_device_paused',
            deviceName: 'Máy Gửi Tạm Dừng',
            platform: 'android',
            isActive: false,
            pairedAt: 1727620000,
            isSender: true,
          ),
        ];

        await tester.pumpWidget(
          BlocProvider(
            create: (_) => PairedSendersBloc(mock)
              ..add(const PairedSendersLoadEvent()),
            child: const MaterialApp(home: Scaffold(body: PairedSendersBody())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Máy Gửi Tạm Dừng'), findsOneWidget);
        expect(find.text('Người gửi tạm dừng'), findsOneWidget);
        expect(
          find.textContaining('Người gửi đang tạm dừng truyền tin. (Chỉ xem)'),
          findsOneWidget,
        );
      },
    );
  });
}
