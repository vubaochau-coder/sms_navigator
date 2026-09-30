import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/bottom_sheet_utils.dart';
import 'package:sms_navigator/core/utils/dialog_utils.dart';
import 'package:sms_navigator/core/utils/toast_utils.dart';
import 'package:sms_navigator/core/utils/ui_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ToastUtils Tests', () {
    testWidgets('ToastUtils shows toast with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ToastUtils.showSuccess(context, 'Thành công!');
                },
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.text('Thành công!'), findsOneWidget);
    });

    testWidgets('ToastUtils shows error, warning, info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => ToastUtils.showError(context, 'Lỗi!'),
                    child: const Text('Error'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        ToastUtils.showWarning(context, 'Cảnh báo!'),
                    child: const Text('Warning'),
                  ),
                  ElevatedButton(
                    onPressed: () => ToastUtils.showInfo(context, 'Thông tin!'),
                    child: const Text('Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Error'));
      await tester.pump();
      expect(find.text('Lỗi!'), findsOneWidget);

      await tester.tap(find.text('Warning'));
      await tester.pump();
      expect(find.text('Cảnh báo!'), findsOneWidget);

      await tester.tap(find.text('Info'));
      await tester.pump();
      expect(find.text('Thông tin!'), findsOneWidget);
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
    testWidgets(
      'UiUtils delegates to ToastUtils, DialogUtils, BottomSheetUtils',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UiUtils.showSuccessToast(context, 'Facade Toast');
                  },
                  child: const Text('Show Facade Toast'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Facade Toast'));
        await tester.pump();

        expect(find.text('Facade Toast'), findsOneWidget);
      },
    );
  });
}
