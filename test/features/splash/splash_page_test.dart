import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/bootstrap/app_bootstrap.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/features/splash/presentation/pages/splash_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('SplashPage displays branding and app title', (
    WidgetTester tester,
  ) async {
    final localStorage = await LocalStorageService.create();

    await tester.pumpWidget(
      AppBootstrap(
        localStorageService: localStorage,
        initializeAsyncServices: false,
        child: const MaterialApp(
          home: SplashPage(autoStart: false),
        ),
      ),
    );

    expect(find.text('SMS Navigator'), findsOneWidget);
    expect(find.text('Ghép đôi và đồng bộ SMS an toàn'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.sms_rounded), findsOneWidget);
  });
}
