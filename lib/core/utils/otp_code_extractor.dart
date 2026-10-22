/// Tách mã OTP (4–8 chữ số) khỏi nội dung SMS để hiện thẳng trên thông báo
/// và sao chép bằng một chạm.
///
/// Quy tắc:
/// 1. Ưu tiên số đứng gần từ khoá (OTP, mã xác thực, code, PIN…), trước hết
///    là số đứng **sau** từ khoá, sau đó là số đứng ngay **trước** từ khoá.
/// 2. Không có từ khoá → chỉ trả về khi tin có **đúng một** ứng viên.
/// 3. Loại số tiền (`1.000.000đ`, `500000 VND`), ngày (`21/10/2026`), giờ,
///    số thập phân và số điện thoại (dài hơn 8 chữ số).
abstract final class OtpCodeExtractor {
  static final RegExp _keyword = RegExp(
    r'(?<!\p{L})(otp|passcode|password|verification|code|pin|m[ãa](?:\s*(?:x[áa]c\s*(?:th[ựu]c|nh[ậa]n)|b[ảa]o\s*m[ậa]t|giao\s*d[ịi]ch|kh[óo]a))?)(?!\p{L})',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _candidate = RegExp(
    r'(?<!\d)(?<!\d[.,:/])(\d{4,8})(?!\d)(?![.,:/]\d)(?!\s*(?:đ|vnd|vnđ|usd|%|k(?!\p{L})))',
    caseSensitive: false,
    unicode: true,
  );

  /// Khoảng cách tối đa (ký tự) giữa từ khoá và mã.
  static const int _afterWindow = 40;
  static const int _beforeWindow = 20;

  static String? extract(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    final candidates = _candidate.allMatches(text).toList();
    if (candidates.isEmpty) return null;

    final keywords = _keyword.allMatches(text).toList();
    for (final keyword in keywords) {
      for (final candidate in candidates) {
        final gap = candidate.start - keyword.end;
        if (gap >= 0 && gap <= _afterWindow) return candidate.group(1);
      }
    }
    for (final keyword in keywords) {
      for (final candidate in candidates.reversed) {
        final gap = keyword.start - candidate.end;
        if (gap >= 0 && gap <= _beforeWindow) return candidate.group(1);
      }
    }

    final distinct = candidates.map((m) => m.group(1)).toSet();
    return distinct.length == 1 ? distinct.single : null;
  }
}
