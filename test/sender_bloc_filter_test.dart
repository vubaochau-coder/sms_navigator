import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/sender/data/models/relay_log_model.dart';
import 'package:sms_navigator/features/sender/data/repositories/sender_repository.dart';
import 'package:sms_navigator/features/sender/presentation/bloc/sender_bloc.dart';
import 'package:sms_navigator/features/sender/presentation/bloc/sender_event.dart';

class _FakeSenderRepository implements SenderRepository {
  bool relayEnabled = true;
  String currentMode = 'OTP_ONLY';
  List<String> whitelist = [];
  bool batteryOptimization = true;

  @override
  Future<Map<String, dynamic>> getRelayStatus() async {
    return {
      'isRelayEnabled': relayEnabled,
      'pairId': 'test_pair_123',
      'deviceId': 'test_device_456',
      'relayMode': currentMode,
      'senderWhitelist': whitelist,
    };
  }

  @override
  Future<bool> setRelayEnabled(bool isEnabled) async {
    relayEnabled = isEnabled;
    return true;
  }

  @override
  Future<bool> setRelayMode(String relayMode) async {
    currentMode = relayMode;
    return true;
  }

  @override
  Future<bool> setSenderWhitelist(List<String> list) async {
    whitelist = List.from(list);
    return true;
  }

  @override
  Future<List<RelayLogModel>> getRecentLogs() async => [];

  @override
  Future<bool> checkBatteryOptimization() async => batteryOptimization;

  @override
  Future<bool> requestBatteryOptimization() async => true;

  @override
  Future<bool> unpairDevice() async => true;

  @override
  void registerOtpListener(Function(String sender, String otp) listener) {}
}

void main() {
  late _FakeSenderRepository fakeRepository;
  late SenderBloc bloc;

  setUp(() {
    fakeRepository = _FakeSenderRepository();
    bloc = SenderBloc(repository: fakeRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test(
    'SenderLoadStatusEvent loads relayMode and senderWhitelist correctly',
    () async {
      fakeRepository.currentMode = 'WHITELIST_ALL';
      fakeRepository.whitelist = ['+86', '1069'];

      bloc.add(const SenderLoadStatusEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isLoading == true),
          predicate<dynamic>(
            (s) =>
                s.isLoading == false &&
                s.relayMode == 'WHITELIST_ALL' &&
                s.senderWhitelist.length == 2 &&
                s.senderWhitelist.contains('+86'),
          ),
        ]),
      );
    },
  );

  test('SenderUpdateRelayModeEvent updates relayMode', () async {
    bloc.add(const SenderUpdateRelayModeEvent('ALL_SMS'));

    await expectLater(
      bloc.stream,
      emits(predicate<dynamic>((s) => s.relayMode == 'ALL_SMS')),
    );
    expect(fakeRepository.currentMode, 'ALL_SMS');
  });

  test('SenderAddWhitelistPrefixEvent adds valid unique prefixes', () async {
    bloc.add(const SenderAddWhitelistPrefixEvent('+86'));

    await expectLater(
      bloc.stream,
      emits(
        predicate<dynamic>(
          (s) =>
              s.senderWhitelist.contains('+86') &&
              s.senderWhitelist.length == 1,
        ),
      ),
    );

    // Duplicate prefix should not be added again
    bloc.add(const SenderAddWhitelistPrefixEvent('+86'));
    expect(fakeRepository.whitelist.length, 1);
  });

  test('SenderRemoveWhitelistPrefixEvent removes prefix from list', () async {
    fakeRepository.whitelist = ['+86', '1069'];
    bloc.add(const SenderLoadStatusEvent());
    await bloc.stream.firstWhere((s) => !s.isLoading);

    bloc.add(const SenderRemoveWhitelistPrefixEvent('+86'));

    await expectLater(
      bloc.stream,
      emits(
        predicate<dynamic>(
          (s) =>
              !s.senderWhitelist.contains('+86') &&
              s.senderWhitelist.contains('1069'),
        ),
      ),
    );
    expect(fakeRepository.whitelist, ['1069']);
  });
}
