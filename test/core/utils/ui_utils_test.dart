import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/ui_utils.dart';
import 'package:toastification/toastification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    toastification.dismissAll();
  });

  group('ToastUtils with Toastification Tests', () {
    testWidgets('ToastUtils shows toast without context parameter', (
      tester,
    ) async {
      await tester.pumpWidget(
        ToastificationWrapper(
          child: MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  ToastUtils.showSuccess('Thao tác thành công!');
                },
                child: const Text('Show Success Without Context'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success Without Context'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Thao tác thành công!'), findsOneWidget);

      toastification.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('ToastUtils shows error, warning, info without context', (
      tester,
    ) async {
      await tester.pumpWidget(
        ToastificationWrapper(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => ToastUtils.showError('Có lỗi xảy ra!'),
                    child: const Text('Error'),
                  ),
                  ElevatedButton(
                    onPressed: () => ToastUtils.showWarning('Lưu ý cảnh báo!'),
                    child: const Text('Warning'),
                  ),
                  ElevatedButton(
                    onPressed: () => ToastUtils.showInfo('Thông báo tin nhắn'),
                    child: const Text('Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Error
      await tester.tap(find.text('Error'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Có lỗi xảy ra!'), findsOneWidget);

      // Warning
      await tester.tap(find.text('Warning'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Lưu ý cảnh báo!'), findsOneWidget);

      // Info
      await tester.tap(find.text('Info'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Thông báo tin nhắn'), findsOneWidget);

      toastification.dismissAll();
      await tester.pumpAndSettle();
    });
  });

  group('DialogUtils Tests', () {
    testWidgets('DialogUtils shows confirm dialog and returns boolean', (
      tester,
    ) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await DialogUtils.showConfirmDialog(
                    context,
                    title: 'Xóa kết nối',
                    message: 'Bạn có chắc chắn muốn xóa?',
                    confirmText: 'Đồng ý',
                    cancelText: 'Bỏ qua',
                    isDestructive: true,
                    icon: Icons.delete_outline,
                  );
                },
                child: const Text('Confirm Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Confirm Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Xóa kết nối'), findsOneWidget);
      expect(find.text('Bạn có chắc chắn muốn xóa?'), findsOneWidget);
      expect(find.text('Đồng ý'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Xóa kết nối'), findsNothing);
    });
  });

  group('BottomSheetUtils Tests', () {
    testWidgets('BottomSheetUtils opens bottom sheet and displays content', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomSheetUtils.showAppBottomSheet(
                    context,
                    title: 'Tiêu đề Sheet',
                    child: const Text('Nội dung BottomSheet'),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu đề Sheet'), findsOneWidget);
      expect(find.text('Nội dung BottomSheet'), findsOneWidget);

      // Close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu đề Sheet'), findsNothing);
    });
  });

  group('UiUtils Facade backward compatibility', () {
    testWidgets('UiUtils delegates to ToastUtils without context', (
      tester,
    ) async {
      await tester.pumpWidget(
        ToastificationWrapper(
          child: MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  UiUtils.showSuccessToast('Facade Toast Message');
                },
                child: const Text('Show Facade Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Facade Toast'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Facade Toast Message'), findsOneWidget);

      toastification.dismissAll();
      await tester.pumpAndSettle();
    });
  });
}
