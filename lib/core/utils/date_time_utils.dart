import 'package:intl/intl.dart';

/// Bộ tiện ích định dạng ngày tháng và thời gian chung cho toàn bộ ứng dụng SMS Navigator.
class DateTimeUtils {
  DateTimeUtils._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _timeWithSecondsFormat = DateFormat('HH:mm:ss');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateTimeWithSecondsFormat = DateFormat(
    'dd/MM/yyyy HH:mm:ss',
  );

  /// Định dạng ngày (mặc định: `dd/MM/yyyy`)
  static String formatDate(DateTime? dateTime, {String? pattern}) {
    if (dateTime == null) return '--';
    final local = dateTime.toLocal();
    if (pattern != null) {
      return DateFormat(pattern).format(local);
    }
    return _dateFormat.format(local);
  }

  /// Định dạng ngày chuẩn ISO `yyyy-MM-dd` (thường dùng cho API query params)
  static String formatIsoDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _isoDateFormat.format(dateTime.toLocal());
  }

  /// Định dạng giờ (mặc định: `HH:mm`, có giây: `HH:mm:ss`)
  static String formatTime(DateTime? dateTime, {bool includeSeconds = false}) {
    if (dateTime == null) return '--';
    final local = dateTime.toLocal();
    return includeSeconds
        ? _timeWithSecondsFormat.format(local)
        : _timeFormat.format(local);
  }

  /// Định dạng ngày và giờ (mặc định: `dd/MM/yyyy HH:mm`)
  static String formatDateTime(
    DateTime? dateTime, {
    bool includeSeconds = false,
  }) {
    if (dateTime == null) return '--';
    final local = dateTime.toLocal();
    return includeSeconds
        ? _dateTimeWithSecondsFormat.format(local)
        : _dateTimeFormat.format(local);
  }

  /// Định dạng thời gian tương đối thân thiện (VD: "Vừa xong", "5 phút trước", "Hôm qua")
  static String timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inSeconds < 45) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${formatTime(local)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return formatDate(local);
    }
  }

  /// Kiểm tra 2 mốc thời gian có cùng ngày hay không
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  /// Lấy mốc 00:00:00.000 đầu ngày
  static DateTime startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Lấy mốc 23:59:59.999 cuối ngày
  static DateTime endOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day, 23, 59, 59, 999);
  }

  /// Parse chuỗi ngày ISO `yyyy-MM-dd` an toàn
  static DateTime? parseIsoDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return _isoDateFormat.parseStrict(dateStr.trim());
    } catch (_) {
      return null;
    }
  }

  /// Parse chuỗi thời gian ISO-8601 an toàn, trả về null nếu chuỗi rỗng hoặc không đúng định dạng.
  /// Chuỗi UTC (đuôi `Z`) được convert về giờ máy trước khi format để tránh lệch múi giờ.
  static DateTime? tryParse(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return null;
    return DateTime.tryParse(isoString.trim())?.toLocal();
  }

  /// Parse chuỗi thời gian ISO-8601, nếu lỗi hoặc rỗng trả về mốc mặc định (fallback hoặc epoch 0).
  static DateTime parseOrDefault(String? isoString, {DateTime? fallback}) {
    return tryParse(isoString) ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
