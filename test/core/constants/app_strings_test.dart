import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/constants/app_strings.dart';
import 'package:sms_navigator/core/l10n/app_l10n.dart';

void main() {
  test('const default device name matches the localized one', () {
    expect(AppStrings.defaultDeviceName, AppL10n.current.splashDefaultDeviceName);
  });
}
