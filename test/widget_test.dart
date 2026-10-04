import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/app.dart';
import 'package:sms_navigator/core/bootstrap/app_bootstrap.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';

import 'package:sms_navigator/features/home/main_navigation_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final localStorage = await LocalStorageService.create();
    await tester.pumpWidget(
      AppBootstrap(
        localStorageService: localStorage,
        initializeAsyncServices: false,
        child: const OtpRelayApp(home: MainNavigationPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('App displays MainNavigationPage with SMS and Channel tabs', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // Verify bottom navigation bar with 2 tabs
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    expect(find.text('Kênh'), findsOneWidget);

    // Verify center docked QR scanner FAB
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Channel tab switches to ChannelPage', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Kênh'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Kênh'), findsWidgets);
  });
}
