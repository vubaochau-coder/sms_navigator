import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';
import 'package:sms_navigator/features/scanner/presentation/pages/qr_scan_page.dart';
import 'package:sms_navigator/features/scanner/presentation/scanning/qr_scan_handler.dart';
import 'package:sms_navigator/features/scanner/presentation/scanning/qr_scan_handler_registry.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _RecordingScanHandler implements QrScanHandler {
  final handledQr = <String>[];

  @override
  bool canHandle(String raw) => raw.startsWith('smsnavigator://');

  @override
  void handleScan(BuildContext context, QrScanFlow flow, String raw) {
    handledQr.add(raw);
    flow.complete();
  }

  @override
  void dispose() {}
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
    required _RecordingScanHandler handler,
    required MobileScannerController controller,
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => QrScanPage(
                      registry: QrScanHandlerRegistry(handlers: [handler]),
                      controller: controller,
                    ),
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
    'gallery image containing a supported QR dispatches to the handler',
    (tester) async {
      final handler = _RecordingScanHandler();
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(
          barcodes: [Barcode(rawValue: _validPairingQr)],
        ),
      );
      mockImagePicker('/tmp/fake_qr.png');

      await pumpScannerPage(tester, handler: handler, controller: controller);
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(handler.handledQr, [_validPairingQr]);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'unrecognized QR payload shows a toast and is not dispatched',
    (tester) async {
      final handler = _RecordingScanHandler();
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(
          barcodes: [
            Barcode(rawValue: 'https://example.com/some/other/qr'),
          ],
        ),
      );
      mockImagePicker('/tmp/foreign_qr.png');

      await pumpScannerPage(tester, handler: handler, controller: controller);
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(handler.handledQr, isEmpty);
      expect(
        find.text('Mã QR này không được SMS Navigator hỗ trợ'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'gallery image without a QR code shows an error and does not submit',
    (tester) async {
      final handler = _RecordingScanHandler();
      final controller = _FakeScannerController(
        analyzeResult: const BarcodeCapture(),
      );
      mockImagePicker('/tmp/no_qr.png');

      await pumpScannerPage(tester, handler: handler, controller: controller);
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(handler.handledQr, isEmpty);
      expect(find.byType(QrScanPage), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'cancelling the gallery picker does not submit any event',
    (tester) async {
      final handler = _RecordingScanHandler();
      final controller = _FakeScannerController();
      mockImagePicker(null);

      await pumpScannerPage(tester, handler: handler, controller: controller);
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await pumpFrames(tester);

      expect(handler.handledQr, isEmpty);
      expect(find.byType(QrScanPage), findsOneWidget);
    },
  );
}
