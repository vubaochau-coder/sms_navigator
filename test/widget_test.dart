import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/app.dart';
import 'package:sms_navigator/core/constants/app_strings.dart';
import 'package:sms_navigator/core/di/injection.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DependencyContainer.instance.init();
  });

  testWidgets('App displays Role Selection with Sender and Receiver options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OtpRelayApp());
    await tester.pumpAndSettle();

    // Verify Title and Subtitle are displayed
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.roleSelectionSubtitle), findsOneWidget);

    // Verify Role Cards are present
    expect(find.text(AppStrings.roleSenderTitle), findsOneWidget);
    expect(find.text(AppStrings.roleReceiverTitle), findsOneWidget);
  });

  testWidgets('Theme toggle switches app between light and dark mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OtpRelayApp());
    await tester.pumpAndSettle();

    MaterialApp appMaterial(WidgetTester tester) {
      return tester.widget<MaterialApp>(find.byType(MaterialApp));
    }

    // Default (system) starts as light in the test environment.
    expect(appMaterial(tester).themeMode, isNot(ThemeMode.dark));
    final brightnessBefore = appMaterial(tester).themeMode;

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    expect(appMaterial(tester).themeMode, ThemeMode.dark);
    expect(appMaterial(tester).themeMode, isNot(brightnessBefore));

    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();

    expect(appMaterial(tester).themeMode, ThemeMode.light);
  });
}
