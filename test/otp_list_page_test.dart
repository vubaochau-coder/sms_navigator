import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/di/injection.dart';
import 'package:sms_navigator/features/otp_list/presentation/pages/otp_list_page.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DependencyContainer.instance.init();
  });

  testWidgets('OtpListPage renders TableCalendar and initial empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpListPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify AppBar
    expect(find.text('Danh Sách OTP'), findsOneWidget);

    // Verify TableCalendar is rendered
    expect(find.byType(TableCalendar), findsOneWidget);

    // Verify Grouping toggle button is present
    expect(find.text('Nhóm theo máy'), findsOneWidget);
  });
}
