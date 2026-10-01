import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/bootstrap/app_bootstrap.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/core/theme/theme_cubit.dart';
import 'package:sms_navigator/features/otp_list/presentation/pages/otp_list_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('OtpListPage renders TableCalendar and initial empty state', (
    WidgetTester tester,
  ) async {
    final localStorage = await LocalStorageService.create();
    await tester.pumpWidget(
      AppBootstrap(
        localStorageService: localStorage,
        initializeAsyncServices: false,
        child: BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(localStorage: localStorage),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: OtpListPage(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify TableCalendar is rendered
    expect(find.byType(TableCalendar), findsOneWidget);

    // Verify Grouping toggle button is present
    expect(find.text('Nhóm theo máy'), findsOneWidget);
  });
}
