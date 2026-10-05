import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';
import 'package:sms_navigator/features/scanner/qr_scan_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

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

const String _validPairingQr =
    'smsnavigator://pair?v=4&s=session_123&t=token_abc&u=aHR0cHM6Ly9hcGkuaW8%3D&e=1790999999999';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockImagePicker(String? imagePath) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (call) async {
        if (call.method == 'pickImage') {
          return imagePath;
        }
        return null;
      },
    );
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpScannerPage(
    WidgetTester tester, {
    required MobileScannerController controller,
    required void Function(ScanQrResult? result) onResult,
    bool Function(String raw)? validator,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ToastificationWrapper(
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<ScanQrResult>(
                    MaterialPageRoute(
                      builder: (_) => QrScanPage(
                        controller: controller,
                        validator: validator,
                      ),
                    ),
                  );
                  onResult(result);
                },
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
    'gallery image containing a supported QR pops and returns ScanQrResult',
    (tester) async {
      ScanQrResult? returnedResult;
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(
          barcodes: [Barcode(rawValue: _validPairingQr)],
        ),
      );
      mockImagePicker('/tmp/fake_qr.png');

      await pumpScannerPage(
        tester,
        controller: controller,
        onResult: (result) => returnedResult = result,
      );
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(returnedResult, const ScanQrResult(rawValue: _validPairingQr));
      expect(find.byType(QrScanPage), findsNothing);
    },
  );

  testWidgets(
    'unrecognized QR payload shows a toast and does not pop',
    (tester) async {
      ScanQrResult? returnedResult;
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(
          barcodes: [
            Barcode(rawValue: 'https://example.com/some/other/qr'),
          ],
        ),
      );
      mockImagePicker('/tmp/foreign_qr.png');

      await pumpScannerPage(
        tester,
        controller: controller,
        onResult: (result) => returnedResult = result,
      );
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(returnedResult, isNull);
      expect(
        find.text('Mã QR này không được SMS Navigator hỗ trợ'),
        findsOneWidget,
      );
      expect(find.byType(QrScanPage), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'gallery image without a QR code shows an error and does not submit',
    (tester) async {
      ScanQrResult? returnedResult;
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(),
      );
      mockImagePicker('/tmp/no_qr.png');

      await pumpScannerPage(
        tester,
        controller: controller,
        onResult: (result) => returnedResult = result,
      );
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(returnedResult, isNull);
      expect(find.byType(QrScanPage), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'cancelling the gallery picker does not submit any event',
    (tester) async {
      ScanQrResult? returnedResult;
      final controller = _FakeScannerController();
      mockImagePicker(null);

      await pumpScannerPage(
        tester,
        controller: controller,
        onResult: (result) => returnedResult = result,
      );
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(returnedResult, isNull);
      expect(find.byType(QrScanPage), findsOneWidget);
    },
  );
}
