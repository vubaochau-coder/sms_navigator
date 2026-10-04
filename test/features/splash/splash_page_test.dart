import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/bootstrap/app_bootstrap.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/features/home/pages/main_navigation_page.dart';
import 'package:sms_navigator/features/splash/pages/splash_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('SplashPage displays branding and app title with l10n', (
    WidgetTester tester,
  ) async {
    final localStorage = await LocalStorageService.create();

    await tester.pumpWidget(
      AppBootstrap(
        localStorageService: localStorage,
        initializeAsyncServices: false,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('vi'),
          home: SplashPage(autoStart: false),
        ),
      ),
    );

    expect(find.text('SMS Navigator'), findsOneWidget);
    expect(find.text('Ghép đôi và đồng bộ SMS an toàn'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.sms_rounded), findsOneWidget);
  });

  testWidgets('SplashPage mounts cleanly with autoStart: true without InheritedWidget error', (
    WidgetTester tester,
  ) async {
    final localStorage = await LocalStorageService.create();

    await tester.pumpWidget(
      AppBootstrap(
        localStorageService: localStorage,
        initializeAsyncServices: false,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('vi'),
          home: SplashPage(),
        ),
      ),
    );

    // Initial build without error
    expect(find.text('SMS Navigator'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
  });

  testWidgets('MainNavigationPage with multiple FABs does not throw duplicate Hero tag error', (
    WidgetTester tester,
  ) async {
    final localStorage = await LocalStorageService.create();

    await tester.pumpWidget(
      AppBootstrap(
        localStorageService: localStorage,
        initializeAsyncServices: false,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('vi'),
          home: SplashPage(autoStart: false),
        ),
      ),
    );

    // Simulate transition to MainNavigationPage
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationPage()),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MainNavigationPage), findsOneWidget);
  });
}
