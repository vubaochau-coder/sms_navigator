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
    if (pattern != null) {
      return DateFormat(pattern).format(dateTime);
    }
    return _dateFormat.format(dateTime);
  }

  /// Định dạng ngày chuẩn ISO `yyyy-MM-dd` (thường dùng cho API query params)
  static String formatIsoDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _isoDateFormat.format(dateTime);
  }

  /// Định dạng giờ (mặc định: `HH:mm`, có giây: `HH:mm:ss`)
  static String formatTime(DateTime? dateTime, {bool includeSeconds = false}) {
    if (dateTime == null) return '--';
    return includeSeconds
        ? _timeWithSecondsFormat.format(dateTime)
        : _timeFormat.format(dateTime);
  }

  /// Định dạng ngày và giờ (mặc định: `dd/MM/yyyy HH:mm`)
  static String formatDateTime(
    DateTime? dateTime, {
    bool includeSeconds = false,
  }) {
    if (dateTime == null) return '--';
    return includeSeconds
        ? _dateTimeWithSecondsFormat.format(dateTime)
        : _dateTimeFormat.format(dateTime);
  }

  /// Định dạng từ timestamp epoch giây (thường trả về từ server backend)
  static String formatEpochSeconds(
    int? epochSeconds, {
    bool includeSeconds = true,
  }) {
    if (epochSeconds == null || epochSeconds <= 0) return '--';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return formatDateTime(dt, includeSeconds: includeSeconds);
  }

  /// Định dạng thời gian tương đối thân thiện (VD: "Vừa xong", "5 phút trước", "Hôm qua")
  static String timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 45) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Kiểm tra 2 mốc thời gian có cùng ngày hay không
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Lấy mốc 00:00:00.000 đầu ngày
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Lấy mốc 23:59:59.999 cuối ngày
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
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
}
