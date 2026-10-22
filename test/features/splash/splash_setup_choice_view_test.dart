import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/theme/app_theme.dart';
import 'package:sms_navigator/features/splash/views/splash_setup_choice_view.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

void main() {
  testWidgets('SplashChoiceButton renders under AppTheme.lightTheme without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SplashChoiceButton(
                icon: Icons.add_moderator_rounded,
                title: 'Tạo danh tính thiết bị mới',
                subtitle: 'Khởi tạo cặp khoá mới và đăng ký thiết bị lên hệ thống relay',
                primary: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    // Should find the button, icon, title, subtitle and not throw overflow exceptions
    expect(find.text('Tạo danh tính thiết bị mới'), findsOneWidget);
    expect(find.byType(SplashChoiceButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
