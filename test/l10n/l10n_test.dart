import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations loads Vietnamese strings correctly', (
    tester,
  ) async {
    late AppLocalizations localizations;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Builder(
          builder: (context) {
            localizations = AppLocalizations.of(context)!;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(localizations.appTitle, equals('OTP Relay'));
    expect(localizations.roleSelectionTitle, equals('Chọn Chế Độ Hoạt Động'));
    expect(localizations.roleSenderTitle, equals('Máy Gửi (Việt Nam)'));
    expect(localizations.roleReceiverTitle, equals('Máy Nhận (Malaysia)'));
    expect(localizations.confirm, equals('Xác nhận'));
    expect(localizations.cancel, equals('Hủy bỏ'));
    expect(
      localizations.copiedWithLabel('Mã OTP', '123456'),
      equals('Đã sao chép Mã OTP: 123456'),
    );
    expect(
      localizations.relayModeChanged('OTP_ONLY'),
      equals('Đã chuyển sang chế độ: OTP_ONLY'),
    );
    expect(
      localizations.addWhitelistSuccess('1555'),
      equals('Đã thêm đầu số 1555 vào bộ lọc'),
    );
    expect(
      localizations.themeSwitchToLight,
      equals('Chuyển sang nền sáng'),
    );
    expect(
      localizations.themeSwitchToDark,
      equals('Chuyển sang nền tối'),
    );
  });
}
