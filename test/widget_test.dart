import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/app.dart';
import 'package:sms_navigator/core/di/injection.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DependencyContainer.instance.init();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const OtpRelayApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('App displays MainNavigationPage with SMS and Pairing tabs', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // Verify bottom navigation bar with 2 tabs
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    expect(find.text('Ghép nối'), findsOneWidget);

    // Verify center docked QR scanner FAB
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Pairing tab shows PairingHubPage with receivers and senders', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Ghép nối'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Ghép Nối Thiết Bị'), findsOneWidget);
    expect(find.text('Máy nhận'), findsOneWidget);
    expect(find.text('Máy gửi'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
