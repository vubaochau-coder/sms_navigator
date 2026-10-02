import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';
import 'package:sms_navigator/features/pairing/data/models/sender_link_status.dart';
import 'package:sms_navigator/features/pairing/data/repositories/pairing_repository.dart';
import 'package:sms_navigator/features/pairing/data/services/pairing_service.dart';
import 'package:sms_navigator/features/pairing/data/services/qr_image_export_service.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/pairing_bloc.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/pairing_event.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/pairing_state.dart';

class _FakePairingRepository implements PairingRepository {
  _FakePairingRepository({
    required this.onSubmitQr,
    this.exportError,
    this.linkStatus = SenderLinkStatus.waiting,
  });

  final bool Function(String qrData) onSubmitQr;

  /// Lỗi ném ra khi export QR; null = export thành công.
  final Object? exportError;

  /// Trạng thái poll liên kết Máy B trả về.
  SenderLinkStatus linkStatus;

  int linkPollCallCount = 0;
  int exportCallCount = 0;

  @override
  Future<PairingPayloadModel> createSenderPairingSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return PairingPayloadModel(
      pairId: 'pair_fake',
      pairingKey: 'fake_pairing_key_value',
      senderPubkey: 'ZmFrZV9wdWJsaWNfa2V5XzMyX2J5dGVzX2FhYQ==',
      senderPrivateKeyBase64: 'ZmFrZV9wcml2YXRlX2tleV8zMl9ieXRlc19hYQ==',
      createdAt: now,
      expiresAt: now + 60000,
    );
  }

  @override
  Future<bool> applySenderPairing(PairingPayloadModel payload) async => true;

  @override
  Future<SenderLinkStatus> checkSenderPairingLink(
    PairingPayloadModel payload,
  ) async {
    linkPollCallCount++;
    return linkStatus;
  }

  @override
  Future<bool> submitReceiverPairingQr(String qrData) async =>
      onSubmitQr(qrData);

  @override
  Future<bool> submitReceiverPairingCode(String code) async =>
      submitReceiverPairingQr(code);

  @override
  Future<PairingPayloadModel?> checkReceiverPairingStatus() async => null;

  @override
  Future<bool> disconnectReceiver() async => true;

  @override
  Future<void> exportPairingQr(PairingPayloadModel payload) async {
    exportCallCount++;
    final error = exportError;
    if (error != null) throw error;
  }
}

Future<List<PairingState>> _collectUntil(
  PairingBloc bloc,
  bool Function(PairingState) predicate,
) async {
  final states = <PairingState>[];
  final done = Completer<void>();
  late final StreamSubscription<PairingState> subscription;
  subscription = bloc.stream.listen((state) {
    states.add(state);
    if (predicate(state) && !done.isCompleted) {
      done.complete();
    }
  });
  await done.future.timeout(const Duration(seconds: 5));
  await subscription.cancel();
  return states;
}

void main() {
  test('submitting a valid QR emits success and paired state', () async {
    final bloc = PairingBloc(
      repository: _FakePairingRepository(onSubmitQr: (_) => true),
    );

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.isSuccess && state.isPaired,
    );
    bloc.add(
      const PairingSubmitReceiverQrEvent(
        '{"v":3,"k":"pairkey1234567890","a":"c2VuZGVyX3B1Yl9iYXNlNjRfMzJfYnl0ZXM="}',
      ),
    );

    final states = await statesFuture;
    await bloc.close();

    expect(states.last.isLoading, isFalse);
    expect(states.last.isSuccess, isTrue);
    expect(states.last.isPaired, isTrue);
    expect(states.last.errorMessage, isNull);
  });

  test('submitting an invalid QR emits an error message', () async {
    final bloc = PairingBloc(
      repository: _FakePairingRepository(onSubmitQr: (_) => false),
    );

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.errorMessage != null,
    );
    bloc.add(const PairingSubmitReceiverQrEvent('bad-qr-data'));

    final states = await statesFuture;
    await bloc.close();

    expect(states.last.isSuccess, isFalse);
    expect(states.last.isPaired, isFalse);
    expect(states.last.errorMessage, 'Mã QR không hợp lệ hoặc đã hết hạn.');
  });

  test('legacy code event routes to the same QR handler', () async {
    final submitted = <String>[];
    final bloc = PairingBloc(
      repository: _FakePairingRepository(
        onSubmitQr: (qrData) {
          submitted.add(qrData);
          return false;
        },
      ),
    );

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.errorMessage != null,
    );
    bloc.add(const PairingSubmitReceiverCodeEvent('123456'));

    final states = await statesFuture;
    await bloc.close();

    expect(submitted, ['123456']);
    expect(states.last.errorMessage, isNotNull);
  });

  test(
    'repository submitReceiverPairingCode forwards to QR submission',
    () async {
      final probe = _ForwardingServiceProbe();
      final repo = PairingRepositoryImpl(
        pairingService: probe,
        qrImageExportService: const QrImageExportServiceImpl(),
      );

      await repo.submitReceiverPairingCode('123456');

      expect(probe.received, ['123456']);
    },
  );

  group('sender link polling (ECDH handoff)', () {
    test('PairingSenderLinkPolled emits isReceiverLinked when repo reports linked', () async {
      final repository = _FakePairingRepository(
        onSubmitQr: (_) => true,
        linkStatus: const SenderLinkStatus(
          linked: true,
          receiverDeviceName: 'Máy B của Minh',
        ),
      );
      final bloc = PairingBloc(repository: repository);
      bloc.add(const PairingGenerateSenderCodeEvent());
      await Future<void>.delayed(Duration.zero);

      final statesFuture = _collectUntil(
        bloc,
        (state) => state.isReceiverLinked,
      );
      bloc.add(const PairingSenderLinkPolled());
      final states = await statesFuture;
      await bloc.close();

      expect(states.last.isReceiverLinked, isTrue);
      expect(repository.linkPollCallCount, 1);
    });

    test('waiting poll result keeps isReceiverLinked false', () async {
      final repository = _FakePairingRepository(onSubmitQr: (_) => true);
      final bloc = PairingBloc(repository: repository);
      bloc.add(const PairingGenerateSenderCodeEvent());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const PairingSenderLinkPolled());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await bloc.close();

      expect(bloc.state.isReceiverLinked, isFalse);
      expect(repository.linkPollCallCount, 1);
    });
  });

  group('PairingExportQrRequested', () {    test('export success emits success status and bumps qrExportToken',
        () async {
      final bloc = PairingBloc(
        repository: _FakePairingRepository(onSubmitQr: (_) => true),
      );
      bloc.add(const PairingGenerateSenderCodeEvent());
      await Future<void>.delayed(Duration.zero);

      final statesFuture = _collectUntil(
        bloc,
        (state) => state.qrExportToken == 1,
      );
      bloc.add(const PairingExportQrRequested());
      final states = await statesFuture;
      await bloc.close();

      expect(states.last.isExportingQr, isFalse);
      expect(states.last.qrExportStatus, QrExportStatus.success);
      expect(states.last.qrExportToken, 1);
    });

    test(
      'export access-denied failure emits permissionDenied status',
      () async {
        final bloc = PairingBloc(
          repository: _FakePairingRepository(
            onSubmitQr: (_) => true,
            exportError: const QrImageExportException(
              'Chưa được cấp quyền lưu ảnh vào thư viện.',
              accessDenied: true,
            ),
          ),
        );
        bloc.add(const PairingGenerateSenderCodeEvent());
        await Future<void>.delayed(Duration.zero);

        final statesFuture = _collectUntil(
          bloc,
          (state) => state.qrExportToken == 1,
        );
        bloc.add(const PairingExportQrRequested());
        final states = await statesFuture;
        await bloc.close();

        expect(states.last.isExportingQr, isFalse);
        expect(states.last.qrExportStatus, QrExportStatus.permissionDenied);
        expect(states.last.qrExportToken, 1);
      },
    );

    test(
      'export unexpected failure emits genericFailure status',
      () async {
        final bloc = PairingBloc(
          repository: _FakePairingRepository(
            onSubmitQr: (_) => true,
            exportError: const QrImageExportException('Lỗi lưu ảnh'),
          ),
        );
        bloc.add(const PairingGenerateSenderCodeEvent());
        await Future<void>.delayed(Duration.zero);

        final statesFuture = _collectUntil(
          bloc,
          (state) => state.qrExportToken == 1,
        );
        bloc.add(const PairingExportQrRequested());
        final states = await statesFuture;
        await bloc.close();

        expect(states.last.qrExportStatus, QrExportStatus.genericFailure);
        expect(states.last.qrExportToken, 1);
      },
    );

    test(
      'repeated identical export failures bump qrExportToken each time',
      () async {
        final bloc = PairingBloc(
          repository: _FakePairingRepository(
            onSubmitQr: (_) => true,
            exportError: const QrImageExportException('Lỗi lưu ảnh'),
          ),
        );
        bloc.add(const PairingGenerateSenderCodeEvent());
        await Future<void>.delayed(Duration.zero);

        bloc.add(const PairingExportQrRequested());
        await _collectUntil(bloc, (state) => state.qrExportToken == 1);

        bloc.add(const PairingExportQrRequested());
        final states = await _collectUntil(
          bloc,
          (state) => state.qrExportToken == 2,
        );
        await bloc.close();

        expect(states.last.qrExportStatus, QrExportStatus.genericFailure);
        expect(states.last.qrExportToken, 2);
      },
    );

    test('export without payload emits noQr status', () async {
      final repository = _FakePairingRepository(onSubmitQr: (_) => true);
      final bloc = PairingBloc(repository: repository);

      final statesFuture = _collectUntil(
        bloc,
        (state) => state.qrExportToken == 1,
      );
      bloc.add(const PairingExportQrRequested());
      final states = await statesFuture;
      await bloc.close();

      expect(repository.exportCallCount, 0);
      expect(states.last.qrExportStatus, QrExportStatus.noQr);
      expect(states.last.isExportingQr, isFalse);
    });
  });
}

class _ForwardingServiceProbe implements PairingService {
  final List<String> received = [];

  @override
  Future<PairingPayloadModel> generateSenderPairing() async {
    throw UnimplementedError();
  }

  @override
  Future<bool> confirmSenderPairing(PairingPayloadModel payload) async => true;

  @override
  Future<bool> confirmReceiverPairingFromQr(String qrData) async {
    received.add(qrData);
    return qrData.contains('v');
  }

  @override
  Future<bool> confirmReceiverPairing(String data) =>
      confirmReceiverPairingFromQr(data);

  @override
  Future<SenderLinkStatus> checkSenderPairingLink(
    PairingPayloadModel payload,
  ) async => SenderLinkStatus.waiting;

  @override
  Future<PairingPayloadModel?> getReceiverPairing() async => null;

  @override
  Future<bool> clearReceiverPairing() async => true;
}
