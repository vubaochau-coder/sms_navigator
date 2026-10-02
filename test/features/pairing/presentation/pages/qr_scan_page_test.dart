import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';
import 'package:sms_navigator/features/pairing/data/repositories/pairing_repository.dart';
import 'package:sms_navigator/features/pairing/presentation/bloc/pairing_bloc.dart';
import 'package:sms_navigator/features/pairing/presentation/pages/qr_scan_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _RecordingPairingRepository implements PairingRepository {
  final submittedQr = <String>[];

  @override
  Future<PairingPayloadModel> createSenderPairingSession() {
    throw UnimplementedError();
  }

  @override
  Future<bool> applySenderPairing(PairingPayloadModel payload) async => true;

  @override
  Future<bool> submitReceiverPairingQr(String qrData) async {
    submittedQr.add(qrData);
    return true;
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

class _FakeScannerController extends MobileScannerController {
  _FakeScannerController({this.analyzeResult}) : super(autoStart: false);

  final BarcodeCapture? analyzeResult;

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async =>
      analyzeResult;
}

void main() {
  const imagePickerChannel = MethodChannel('plugins.flutter.io/image_picker');

  void mockImagePicker(String? resultPath) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, (call) async {
      if (call.method == 'pickImage') return resultPath;
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(imagePickerChannel, null);
  });

  /// Camera với autoStart=false không bao giờ khởi động nên spinner của
  /// MobileScanner chạy vô hạn — dùng pump cố định thay vì pumpAndSettle.
  /// bloc.close() cũng không được await: Future của close với transformer
  /// droppable không hoàn thành trong môi trường FakeAsync của widget test.
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpScannerPage(
    WidgetTester tester, {
    required PairingBloc bloc,
    required MobileScannerController controller,
  }) async {
    await tester.pumpWidget(
      BlocProvider<PairingBloc>.value(
        value: bloc,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => QrScanPage(controller: controller),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await pumpFrames(tester);
  }

  testWidgets(
    'gallery image containing a QR code submits the pairing event',
    (tester) async {
      final repository = _RecordingPairingRepository();
      final bloc = PairingBloc(repository: repository);
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(
          barcodes: [Barcode(rawValue: '{"v":1,"pairId":"p"}')],
        ),
      );
      mockImagePicker('/tmp/fake_qr.png');

      await pumpScannerPage(tester, bloc: bloc, controller: controller);
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(repository.submittedQr, ['{"v":1,"pairId":"p"}']);
      unawaited(bloc.close());
    },
  );

  testWidgets(
    'gallery image without a QR code shows an error and does not submit',
    (tester) async {
      final repository = _RecordingPairingRepository();
      final bloc = PairingBloc(repository: repository);
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(),
      );
      mockImagePicker('/tmp/no_qr.png');

      await pumpScannerPage(tester, bloc: bloc, controller: controller);
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(repository.submittedQr, isEmpty);
      expect(find.byType(QrScanPage), findsOneWidget);
      unawaited(bloc.close());
    },
  );

  testWidgets(
    'cancelling the gallery picker does not submit any event',
    (tester) async {
      final repository = _RecordingPairingRepository();
      final bloc = PairingBloc(repository: repository);
      final controller = _FakeScannerController();
      mockImagePicker(null);

      await pumpScannerPage(tester, bloc: bloc, controller: controller);
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(repository.submittedQr, isEmpty);
      expect(find.byType(QrScanPage), findsOneWidget);
      unawaited(bloc.close());
    },
  );
}
