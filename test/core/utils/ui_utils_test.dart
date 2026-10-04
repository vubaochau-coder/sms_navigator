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
    test('DialogUtils insetPadding has 12dp horizontal margin', () {
      expect(DialogUtils.insetPadding.left, 12.0);
      expect(DialogUtils.insetPadding.right, 12.0);
    });

    testWidgets('DialogUtils.showBaseForm displays custom child inside dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: DialogUtils.navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showBaseForm(
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Custom Content Inside Base Form'),
                    ),
                    context: context,
                  );
                },
                child: const Text('Open Base Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Base Form'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Content Inside Base Form'), findsOneWidget);
    });

    testWidgets('DialogUtils.showInfoDialog displays message with 1 close button', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: DialogUtils.navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DialogUtils.showInfoDialog(
                    context: context,
                    title: 'Thông báo',
                    message: 'Nội dung thông tin quan trọng.',
                    buttonText: 'Đã hiểu',
                  );
                },
                child: const Text('Open Info Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Info Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Nội dung thông tin quan trọng.'), findsOneWidget);
      expect(find.text('Đã hiểu'), findsOneWidget);

      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Thông báo'), findsNothing);
    });

    testWidgets('DialogUtils.showTwoOptionsDialog handles positive, negative and swap', (
      tester,
    ) async {
      bool? userChoice;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: DialogUtils.navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      userChoice = await DialogUtils.showTwoOptionsDialog(
                        context: context,
                        title: 'Xác nhận xóa',
                        message: 'Bạn có chắc chắn?',
                        positiveText: 'Tiếp tục',
                        negativeText: 'Quay lại',
                        swapButtonPositions: true,
                      );
                    },
                    child: const Text('Two Options Swapped'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Two Options Swapped'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận xóa'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);

      // Verify button positions swapped: Tiếp tục is first
      final tiepTucPos = tester.getTopLeft(find.text('Tiếp tục')).dx;
      final quayLaiPos = tester.getTopLeft(find.text('Quay lại')).dx;
      expect(tiepTucPos, lessThan(quayLaiPos));

      // Tap negative button (Quay lại)
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();

      expect(userChoice, isFalse);
    });

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
                    context: context,
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

    testWidgets('DialogUtils shows input dialog and returns entered text', (
      tester,
    ) async {
      String? enteredName;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  enteredName = await DialogUtils.showInputDialog(
                    context: context,
                    title: 'Tạo kênh mới',
                    labelText: 'Tên kênh',
                    hintText: 'Ví dụ: Kênh nhà',
                    icon: Icons.add_circle_outline_rounded,
                    confirmText: 'Tạo',
                    cancelText: 'Hủy',
                  );
                },
                child: const Text('Open Input Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Input Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Tạo kênh mới'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Kênh Gia Đình');
      await tester.tap(find.text('Tạo'));
      await tester.pumpAndSettle();

      expect(enteredName, equals('Kênh Gia Đình'));
    });

    testWidgets('DialogUtils.showInputDialog maintains 12dp distance to screen edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showInputDialog(
                    context: context,
                    title: 'Đổi tên thiết bị',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final dialogFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Material),
      );
      final dialogRect = tester.getRect(dialogFinder.first);
      expect(dialogRect.left, 12.0);
      expect(dialogRect.right, 388.0);
      expect(dialogRect.width, 376.0);
    });
  });

  group('BottomSheetUtils Tests', () {
    testWidgets('BottomSheetUtils.showBaseForm opens bottom sheet and displays child', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: DialogUtils.navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomSheetUtils.showBaseForm(
                    child: const Text('Base Form Content'),
                    context: context,
                    title: 'Tiêu đề Sheet Base',
                  );
                },
                child: const Text('Open Base Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Base Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu đề Sheet Base'), findsOneWidget);
      expect(find.text('Base Form Content'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu đề Sheet Base'), findsNothing);
    });

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
                    context: context,
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
