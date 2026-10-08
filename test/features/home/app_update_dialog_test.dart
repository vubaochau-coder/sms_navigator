import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/app_update_info_model.dart';
import 'package:sms_navigator/core/repositories/app_update_repository.dart';
import 'package:sms_navigator/features/home/views/app_update_dialog.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeAppUpdateRepository implements AppUpdateRepository {
  int? dismissedBuild;

  @override
  Future<AppUpdateInfoModel?> checkForUpdate() async => null;

  @override
  Future<void> dismissUpdate(int buildNumber) async {
    dismissedBuild = buildNumber;
  }

  @override
  bool isUpdateDismissed(int buildNumber) => dismissedBuild == buildNumber;
}

void main() {
  late _FakeAppUpdateRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeAppUpdateRepository();
  });

  Widget createDialogApp(AppUpdateInfoModel updateInfo) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppUpdateDialog.show(context, updateInfo, fakeRepo),
            child: const Text('Show Dialog'),
          ),
        ),
      ),
    );
  }

  testWidgets('AppUpdateDialog renders title, version badge, description and buttons for optional update', (
    WidgetTester tester,
  ) async {
    const updateInfo = AppUpdateInfoModel(
      latestBuild: 16,
      latestVersion: '0.0.1',
      minBuild: 10,
      title: 'Có phiên bản mới',
      description: 'Hỗ trợ hiển thị Brand Name cho SMS',
      downloadUrl: 'https://example.com/app',
      isForceUpdate: false,
    );

    await tester.pumpWidget(createDialogApp(updateInfo));
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Có phiên bản mới'), findsOneWidget);
    expect(find.text('v0.0.1 (Build 16)'), findsOneWidget);
    expect(find.text('Hỗ trợ hiển thị Brand Name cho SMS'), findsOneWidget);
    expect(find.text('Cập nhật ngay'), findsOneWidget);
    expect(find.text('Để sau'), findsOneWidget);

    // Tap "Để sau" should dismiss and persist dismissal
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    expect(fakeRepo.dismissedBuild, 16);
    expect(find.byType(AppUpdateDialog), findsNothing);
  });

  testWidgets('AppUpdateDialog hides "Để sau" and shows warning for force update', (
    WidgetTester tester,
  ) async {
    const updateInfo = AppUpdateInfoModel(
      latestBuild: 16,
      latestVersion: '0.0.1',
      minBuild: 16,
      title: 'Bản cập nhật quan trọng',
      description: 'Cần nâng cấp để tiếp tục sử dụng hệ thống',
      downloadUrl: 'https://example.com/app',
      isForceUpdate: true,
    );

    await tester.pumpWidget(createDialogApp(updateInfo));
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Bản cập nhật quan trọng'), findsOneWidget);
    expect(find.text('Cập nhật ngay'), findsOneWidget);
    expect(find.text('Để sau'), findsNothing);
    expect(find.text('Bắt buộc cập nhật để tiếp tục sử dụng'), findsOneWidget);
  });
}
