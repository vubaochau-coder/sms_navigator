import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/otp_code_extractor.dart';

void main() {
  group('OtpCodeExtractor', () {
    const cases = <String, String?>{
      'Ma OTP cua quy khach la 123456. Khong chia se ma nay.': '123456',
      'VCB: Mã xác thực giao dịch 1.000.000đ của Quý khách là 482913, hiệu lực 3 phút.': '482913',
      '482913 la ma xac thuc cua ban': '482913',
      'Your verification code is 7788': '7788',
      'OTP: 123456.': '123456',
      'Ma PIN moi: 9081': '9081',
      'Ma giao dich 5566 so tien 300000đ': '5566',
      // Không có từ khoá nhưng chỉ có một ứng viên
      'Shopping 1234 items ngay 21/10/2026': '1234',
      // Số tài khoản / tiền / ngày không phải OTP
      'TK 0123456789 +500,000VND luc 21/10/2026 10:30': null,
      'Chuyen khoan thanh cong 2000000 VND': null,
      // Nhiều ứng viên, không từ khoá → không đoán
      'Hello 1234 and 5678': null,
      'Xin chao': null,
      '': null,
    };

    cases.forEach((text, expected) {
      test('"$text" → $expected', () {
        expect(OtpCodeExtractor.extract(text), expected);
      });
    });

    test('null input', () => expect(OtpCodeExtractor.extract(null), isNull));
  });
}
