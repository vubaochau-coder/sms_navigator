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
      expect(
        DateTimeUtils.formatDateTime(dt, includeSeconds: true),
        '29/09/2026 15:20:30',
      );
      expect(DateTimeUtils.formatDateTime(null), '--');
    });

    test('timeAgo calculates relative description correctly', () {
      final now = DateTime.now();
      expect(
        DateTimeUtils.timeAgo(now.subtract(const Duration(seconds: 10))),
        'Vừa xong',
      );
      expect(
        DateTimeUtils.timeAgo(now.subtract(const Duration(minutes: 5))),
        '5 phút trước',
      );
      expect(
        DateTimeUtils.timeAgo(now.subtract(const Duration(hours: 3))),
        '3 giờ trước',
      );
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

    test('tryParse normalizes UTC ISO string to device-local DateTime', () {
      const utcString = '2026-10-08T09:30:00.000Z';
      final parsed = DateTimeUtils.tryParse(utcString);
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isFalse);
      expect(
        parsed.millisecondsSinceEpoch,
        DateTime.parse(utcString).millisecondsSinceEpoch,
      );
      expect(DateTimeUtils.tryParse(null), isNull);
      expect(DateTimeUtils.tryParse('   '), isNull);
    });

    test('format methods defensively convert UTC DateTime to device-local wall clock', () {
      final utcDt = DateTime.utc(2026, 10, 8, 9, 30, 45);
      final localDt = utcDt.toLocal();

      final expectedTime =
          '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
      expect(DateTimeUtils.formatTime(utcDt), equals(expectedTime));

      final expectedDate =
          '${localDt.day.toString().padLeft(2, '0')}/${localDt.month.toString().padLeft(2, '0')}/${localDt.year}';
      expect(DateTimeUtils.formatDate(utcDt), equals(expectedDate));
    });

    test('isSameDay accurately compares UTC and local DateTime', () {
      final localNow = DateTime.now();
      final utcSameInstant = localNow.toUtc();
      expect(DateTimeUtils.isSameDay(localNow, utcSameInstant), isTrue);
    });
  });
}
