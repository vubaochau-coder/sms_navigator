import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils Tests', () {
    test('formatDate formats DateTime as dd/MM/yyyy by default', () {
      final dt = DateTime(2026, 9, 29, 14, 30, 45);
      expect(DateTimeUtils.formatDate(dt), '29/09/2026');
      expect(DateTimeUtils.formatDate(null), '--');
    });

    test('formatIsoDate formats DateTime as yyyy-MM-dd', () {
      final dt = DateTime(2026, 9, 29);
      expect(DateTimeUtils.formatIsoDate(dt), '2026-09-29');
      expect(DateTimeUtils.formatIsoDate(null), '');
    });

    test('formatTime formats HH:mm and optionally with seconds', () {
      final dt = DateTime(2026, 9, 29, 9, 5, 8);
      expect(DateTimeUtils.formatTime(dt), '09:05');
      expect(DateTimeUtils.formatTime(dt, includeSeconds: true), '09:05:08');
      expect(DateTimeUtils.formatTime(null), '--');
    });

    test('formatDateTime formats date and time with or without seconds', () {
      final dt = DateTime(2026, 9, 29, 15, 20, 30);
      expect(DateTimeUtils.formatDateTime(dt), '29/09/2026 15:20');
      expect(DateTimeUtils.formatDateTime(dt, includeSeconds: true), '29/09/2026 15:20:30');
      expect(DateTimeUtils.formatDateTime(null), '--');
    });

    test('formatEpochSeconds converts epoch seconds to formatted date time', () {
      expect(DateTimeUtils.formatEpochSeconds(null), '--');
      expect(DateTimeUtils.formatEpochSeconds(0), '--');
      final formatted = DateTimeUtils.formatEpochSeconds(1727620000);
      expect(formatted.contains('2024'), isTrue);
    });

    test('timeAgo calculates relative description correctly', () {
      final now = DateTime.now();
      expect(DateTimeUtils.timeAgo(now.subtract(const Duration(seconds: 10))), 'Vừa xong');
      expect(DateTimeUtils.timeAgo(now.subtract(const Duration(minutes: 5))), '5 phút trước');
      expect(DateTimeUtils.timeAgo(now.subtract(const Duration(hours: 3))), '3 giờ trước');
      expect(DateTimeUtils.timeAgo(null), '--');
    });

    test('isSameDay accurately compares dates', () {
      final d1 = DateTime(2026, 9, 29, 10, 0);
      final d2 = DateTime(2026, 9, 29, 23, 59);
      final d3 = DateTime(2026, 9, 30, 0, 1);
      expect(DateTimeUtils.isSameDay(d1, d2), isTrue);
      expect(DateTimeUtils.isSameDay(d1, d3), isFalse);
      expect(DateTimeUtils.isSameDay(d1, null), isFalse);
    });

    test('parseIsoDate parses valid ISO strings and rejects invalid ones', () {
      final parsed = DateTimeUtils.parseIsoDate('2026-09-29');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 9);
      expect(parsed.day, 29);

      expect(DateTimeUtils.parseIsoDate(null), isNull);
      expect(DateTimeUtils.parseIsoDate(''), isNull);
      expect(DateTimeUtils.parseIsoDate('invalid-date'), isNull);
    });
  });
}
