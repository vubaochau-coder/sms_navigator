import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/di/injection.dart';
import 'package:sms_navigator/features/notification_test/presentation/pages/notification_test_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DependencyContainer.instance.init();
  });

  testWidgets(
    'NotificationTestPage renders correctly and shows interactive triggers',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: NotificationTestPage()));

      expect(find.text('Thử Nghiệm Push Notification'), findsOneWidget);
      expect(
        find.text('1. UI Thông Báo Máy Nhận (B) — Khi Có OTP Đến'),
        findsOneWidget,
      );
      expect(
        find.text('2. UI Thông Báo Máy Gửi (A) — Chuyển Tiếp Thành Công'),
        findsOneWidget,
      );
      expect(
        find.text('Bắn Thử Thông Báo Nhận OTP (Device B)'),
        findsOneWidget,
      );
      expect(
        find.text('Bắn Thử Thông Báo Gửi Thành Công (Device A)'),
        findsOneWidget,
      );

      // Tap bank preset filter chip
      await tester.tap(find.text('MBBank'));
      await tester.pump();
      expect(find.text('🔐 Mã OTP từ MBBank'), findsOneWidget);
    },
  );
}
