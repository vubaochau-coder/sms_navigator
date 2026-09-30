import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/otp_list/data/repositories/otp_list_repository.dart';
import 'package:sms_navigator/features/otp_list/domain/models/decrypted_otp_item.dart';
import 'package:sms_navigator/features/otp_list/presentation/bloc/otp_list_bloc.dart';
import 'package:sms_navigator/features/otp_list/presentation/bloc/otp_list_event.dart';

class _FakeOtpListRepository implements OtpListRepository {
  List<DecryptedOtpItem> stubItems = [];
  CancelToken? lastCancelToken;

  @override
  Future<List<DecryptedOtpItem>> getOtpListForDate(
    DateTime date, {
    String? pairId,
    CancelToken? cancelToken,
  }) async {
    lastCancelToken = cancelToken;
    return stubItems;
  }
}

void main() {
  late _FakeOtpListRepository fakeRepository;
  late OtpListBloc bloc;

  final sampleDate = DateTime(2026, 9, 29);
  final item1 = DecryptedOtpItem(
    id: 'item_1',
    pairId: 'pair_123',
    senderDeviceId: 'dev_sender_a',
    senderDeviceName: 'Samsung S24 (Hà Nội)',
    sender: 'Vietcombank',
    otp: '849201',
    fullMessage: 'GD 849201 tai VCB DIGIBANK',
    receivedAt: DateTime(2026, 9, 29, 10, 30),
    sentAtSeconds: 1759134000,
  );
  final item2 = DecryptedOtpItem(
    id: 'item_2',
    pairId: 'pair_123',
    senderDeviceId: 'dev_sender_b',
    senderDeviceName: 'Xiaomi 13 (Việt Nam)',
    sender: '95555',
    otp: '192837',
    fullMessage: '【招商银行】您的验证码是 192837',
    receivedAt: DateTime(2026, 9, 29, 11, 0),
    sentAtSeconds: 1759135000,
  );

  setUp(() {
    fakeRepository = _FakeOtpListRepository();
    bloc = OtpListBloc(repository: fakeRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('OtpListChangeDateEvent updates selectedDate and loads items', () async {
    fakeRepository.stubItems = [item2, item1];

    bloc.add(OtpListChangeDateEvent(sampleDate));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<dynamic>((s) => s.selectedDate == sampleDate),
        predicate<dynamic>((s) => s.isLoading == true),
        predicate<dynamic>(
          (s) =>
              s.isLoading == false &&
              s.items.length == 2 &&
              s.selectedDate == sampleDate,
        ),
      ]),
    );
  });

  test(
    'OtpListToggleGroupEvent toggles grouping and groupedByDevice separates by device',
    () async {
      fakeRepository.stubItems = [item1, item2];
      bloc.add(const OtpListLoadEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(bloc.state.isGroupingByDevice, false);

      bloc.add(const OtpListToggleGroupEvent());

      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>((s) => s.isGroupingByDevice == true)),
      );

      final grouped = bloc.state.groupedByDevice;
      expect(grouped.keys.length, 2);
      expect(grouped.containsKey('Samsung S24 (Hà Nội)'), true);
      expect(grouped.containsKey('Xiaomi 13 (Việt Nam)'), true);
      expect(grouped['Samsung S24 (Hà Nội)']!.first.otp, '849201');
      expect(grouped['Xiaomi 13 (Việt Nam)']!.first.otp, '192837');
    },
  );

  test('OtpListLoadEvent creates and passes non-null CancelToken', () async {
    fakeRepository.stubItems = [item1];
    bloc.add(const OtpListLoadEvent());
    await bloc.stream.firstWhere((s) => !s.isLoading);

    expect(fakeRepository.lastCancelToken, isNotNull);
    expect(fakeRepository.lastCancelToken!.isCancelled, isFalse);
  });
}
