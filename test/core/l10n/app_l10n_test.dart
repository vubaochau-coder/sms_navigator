import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/l10n/app_l10n.dart';

void main() {
  final l10n = AppL10n.current;

  test('AppL10n resolves the Vietnamese bundle without a BuildContext', () {
    expect(l10n.localeName, 'vi');
    expect(l10n.back, 'Quay lại');
  });

  test('placeholders render with quotes and adjacent text intact', () {
    expect(l10n.notificationJoinRequestBody('Pixel 7', 'Kênh VCB'), 'Pixel 7 muốn tham gia kênh "Kênh VCB".');
    expect(l10n.relativeMinutesAgo(5), '5 phút trước');
    expect(l10n.networkConnectTimeout(15), 'Kết nối tới máy chủ quá thời gian chờ (15s).');
    expect(l10n.whitelistVersionLabel(3), 'Phiên bản bộ lọc: v3');
    expect(l10n.channelDetailApproved('Galaxy A23'), 'Đã duyệt Galaxy A23.');
  });

  test('multi-line value keeps its line breaks', () {
    expect(l10n.deviceResetDialogMessage, contains('khỏi máy.\n\nỨng dụng'));
  });
}
