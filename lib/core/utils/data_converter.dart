/// Tiện ích chuyển đổi kiểu dữ liệu an toàn từ JSON/API response sang Model.
/// Hỗ trợ tham số mặc định (defaultValue) hoặc null nếu không thể parse.
class DataConverter {
  DataConverter._();

  /// Chuyển đổi an toàn sang [String]
  static String? cvToString(dynamic value, [String? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Chuyển đổi an toàn sang [int]
  static int? cvToInt(dynamic value, [int? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final clean = value.trim();
      final parsedInt = int.tryParse(clean);
      if (parsedInt != null) return parsedInt;
      final parsedDouble = double.tryParse(clean);
      if (parsedDouble != null) return parsedDouble.toInt();
    }
    return defaultValue;
  }

  /// Chuyển đổi an toàn sang [double]
  static double? cvToDouble(dynamic value, [double? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Chuyển đổi an toàn sang [num]
  static num? cvToNum(dynamic value, [num? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Chuyển đổi an toàn sang [bool]
  /// Hỗ trợ parse từ bool, số (1/0, >0), và chuỗi ("true", "false", "1", "0", "yes", "no", "on", "off")
  static bool? cvToBool(dynamic value, [bool? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value == 1 || value > 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on') {
        return true;
      }
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off') {
        return false;
      }
    }
    return defaultValue;
  }

  /// Chuyển đổi an toàn sang [DateTime]
  /// Hỗ trợ chuỗi ISO-8601, timestamp milliseconds, hoặc timestamp seconds
  static DateTime? cvToDateTime(dynamic value, [DateTime? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is int) {
      // Nếu là timestamp tính bằng giây (10 chữ số)
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final clean = value.trim();
      final parsedDate = DateTime.tryParse(clean);
      if (parsedDate != null) return parsedDate;
      final parsedInt = int.tryParse(clean);
      if (parsedInt != null) {
        return cvToDateTime(parsedInt, defaultValue);
      }
    }
    return defaultValue;
  }

  /// Chuyển đổi an toàn sang [List<T>]
  static List<T> cvToList<T>(
    dynamic value,
    T Function(dynamic item) mapper, [
    List<T> defaultValue = const [],
  ]) {
    if (value == null || value is! List) return defaultValue;
    try {
      return value.map((item) => mapper(item)).toList();
    } catch (_) {
      return defaultValue;
    }
  }

  /// Chuyển đổi an toàn sang [List<String>]
  static List<String> cvToStringList(
    dynamic value, [
    List<String> defaultValue = const [],
  ]) {
    return cvToList<String>(
      value,
      (item) => cvToString(item, '')!,
      defaultValue,
    );
  }

  /// Chuyển đổi an toàn sang [Map<K, V>]
  static Map<K, V>? cvToMap<K, V>(dynamic value, [Map<K, V>? defaultValue]) {
    if (value == null || value is! Map) return defaultValue;
    try {
      return Map<K, V>.from(value);
    } catch (_) {
      return defaultValue;
    }
  }
}
