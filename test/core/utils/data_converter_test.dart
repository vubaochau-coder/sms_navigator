import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sms_navigator/core/utils/data_converter.dart';
import 'package:sms_navigator/core/utils/date_time_utils.dart';

void main() {
  group('DataConverter Tests', () {
    test('cvToString converts various types or returns default/null', () {
      expect(DataConverter.cvToString('hello'), equals('hello'));
      expect(DataConverter.cvToString(123), equals('123'));
      expect(DataConverter.cvToString(true), equals('true'));
      expect(DataConverter.cvToString(null), isNull);
      expect(DataConverter.cvToString(null, 'default'), equals('default'));
    });

    test(
      'cvToInt converts int, double, num, string, bool or returns default/null',
      () {
        expect(DataConverter.cvToInt(42), equals(42));
        expect(DataConverter.cvToInt(42.9), equals(42));
        expect(DataConverter.cvToInt('100'), equals(100));
        expect(DataConverter.cvToInt('100.8'), equals(100));
        expect(DataConverter.cvToInt(true), equals(1));
        expect(DataConverter.cvToInt(false), equals(0));
        expect(DataConverter.cvToInt('invalid'), isNull);
        expect(DataConverter.cvToInt('invalid', 99), equals(99));
        expect(DataConverter.cvToInt(null), isNull);
        expect(DataConverter.cvToInt(null, -1), equals(-1));
      },
    );

    test('cvToDouble converts int, double, string or returns default/null', () {
      expect(DataConverter.cvToDouble(42.5), equals(42.5));
      expect(DataConverter.cvToDouble(42), equals(42.0));
      expect(DataConverter.cvToDouble('12.34'), equals(12.34));
      expect(DataConverter.cvToDouble('abc'), isNull);
      expect(DataConverter.cvToDouble('abc', 0.0), equals(0.0));
      expect(DataConverter.cvToDouble(null), isNull);
    });

    test('cvToBool parses bool, number, strings correctly', () {
      expect(DataConverter.cvToBool(true), isTrue);
      expect(DataConverter.cvToBool(false), isFalse);
      expect(DataConverter.cvToBool(1), isTrue);
      expect(DataConverter.cvToBool(0), isFalse);
      expect(DataConverter.cvToBool('true'), isTrue);
      expect(DataConverter.cvToBool('TRUE'), isTrue);
      expect(DataConverter.cvToBool('1'), isTrue);
      expect(DataConverter.cvToBool('yes'), isTrue);
      expect(DataConverter.cvToBool('on'), isTrue);
      expect(DataConverter.cvToBool('false'), isFalse);
      expect(DataConverter.cvToBool('0'), isFalse);
      expect(DataConverter.cvToBool('no'), isFalse);
      expect(DataConverter.cvToBool('random'), isNull);
      expect(DataConverter.cvToBool(null), isNull);
      expect(DataConverter.cvToBool(null, false), isFalse);
    });

    test('cvToDateTime parses ISO string and timestamps', () {
      final now = DateTime(2026, 9, 30, 10, 0, 0);
      expect(DataConverter.cvToDateTime(now), equals(now));

      final isoStr = '2026-09-30T10:00:00.000Z';
      final parsed = DataConverter.cvToDateTime(isoStr);
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(2026));

      // Milliseconds timestamp
      final epochMs = now.millisecondsSinceEpoch;
      final fromEpoch = DataConverter.cvToDateTime(epochMs);
      expect(fromEpoch, isNotNull);
      expect(fromEpoch!.millisecondsSinceEpoch, equals(epochMs));

      // Seconds timestamp
      final epochSec = epochMs ~/ 1000;
      final fromSec = DataConverter.cvToDateTime(epochSec);
      expect(fromSec, isNotNull);

      expect(DataConverter.cvToDateTime('invalid_date'), isNull);
      expect(DataConverter.cvToDateTime(null), isNull);
      expect(DataConverter.cvToDateTime(null, now), equals(now));
    });

    test('cvToList and cvToStringList map items cleanly', () {
      final rawList = [1, 2, 3];
      final stringList = DataConverter.cvToList<String>(
        rawList,
        (e) => 'item_$e',
      );
      expect(stringList, equals(['item_1', 'item_2', 'item_3']));

      expect(
        DataConverter.cvToList(null, (e) => e, ['fallback']),
        equals(['fallback']),
      );
      expect(
        DataConverter.cvToStringList(['a', 1, true]),
        equals(['a', '1', 'true']),
      );
    });

    test('cvToMap converts map safely', () {
      final map = {'key': 'value', 'count': 10};
      final parsed = DataConverter.cvToMap<String, dynamic>(map);
      expect(parsed, equals(map));
      expect(DataConverter.cvToMap('not_a_map'), isNull);
      expect(DataConverter.cvToMap(null, {'a': 1}), equals({'a': 1}));
    });
  });

  group('cvToDateTime timezone regression (bug: 7h offset on +07:00)', () {
    // Mốc tham chiếu: 08:00 UTC == 15:00 giờ VN (+07:00).
    // Test phải pass trên MỌI máy bất kể timezone nên luôn so với
    // DateTime.parse(...).toLocal() / fromMillisecondsSinceEpoch.
    const utcIso = '2026-10-01T08:00:00.000Z';

    test('ISO string with Z suffix must be normalized to local time', () {
      final parsed = DataConverter.cvToDateTime(utcIso);

      expect(parsed, isNotNull);
      // Trước fix: DateTime.tryParse giữ isUtc == true -> formatter in thô 08:00.
      expect(parsed!.isUtc, isFalse,
          reason: 'ISO UTC phải được convert về local ngay khi parse');
      expect(parsed, equals(DateTime.parse(utcIso).toLocal()));
      // Vẫn đúng tuyệt đối thời điểm (epoch không đổi).
      expect(
        parsed.millisecondsSinceEpoch,
        equals(DateTime.parse(utcIso).millisecondsSinceEpoch),
      );
    });

    test('ISO string with explicit +07:00 offset parses to same instant', () {
      final parsed = DataConverter.cvToDateTime('2026-10-01T15:00:00.000+07:00');

      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isFalse);
      expect(
        parsed.millisecondsSinceEpoch,
        equals(DateTime.parse(utcIso).millisecondsSinceEpoch),
      );
    });

    test('int epoch (seconds & milliseconds) returns local DateTime', () {
      final ms = DateTime.parse(utcIso).millisecondsSinceEpoch;

      final fromMs = DataConverter.cvToDateTime(ms)!;
      final fromSec = DataConverter.cvToDateTime(ms ~/ 1000)!;

      expect(fromMs.isUtc, isFalse);
      expect(fromSec.isUtc, isFalse);
      expect(fromMs.millisecondsSinceEpoch, equals(ms));
      expect(fromSec.millisecondsSinceEpoch, equals(ms));
    });

    test('numeric string epoch is accepted', () {
      final ms = DateTime.parse(utcIso).millisecondsSinceEpoch;

      expect(
        DataConverter.cvToDateTime(ms.toString())!.millisecondsSinceEpoch,
        equals(ms),
      );
      expect(
        DataConverter.cvToDateTime('${ms ~/ 1000}')!.millisecondsSinceEpoch,
        equals(ms),
      );
    });

    test(
      'every input form of the same instant yields identical wall clock',
      () {
        final expected = DateTime.fromMillisecondsSinceEpoch(
          DateTime.parse(utcIso).millisecondsSinceEpoch,
        );

        final forms = <DateTime?>[
          DataConverter.cvToDateTime(utcIso),
          DataConverter.cvToDateTime('2026-10-01T15:00:00.000+07:00'),
          DataConverter.cvToDateTime(
            DateTime.parse(utcIso).millisecondsSinceEpoch,
          ),
          DataConverter.cvToDateTime(
            DateTime.parse(utcIso).millisecondsSinceEpoch ~/ 1000,
          ),
          DataConverter.cvToDateTime(
            '${DateTime.parse(utcIso).millisecondsSinceEpoch}',
          ),
        ];

        for (final parsed in forms) {
          expect(parsed!.isUtc, isFalse);
          // Bất biến cốt lõi: field giờ/phút hiển thị phải khớp giờ local.
          expect(
            '${parsed.hour}:${parsed.minute}',
            equals('${expected.hour}:${expected.minute}'),
          );
        }
      },
    );

    test('ISO UTC formatted via DateTimeUtils shows device-local wall clock', () {
      // Regression trực tiếp của bug UI: trước fix, máy +07:00 pair lúc 15:00
      // hiển thị 08:00. Bất biến: format(cvToDateTime(isoUtc)) phải bằng
      // format(DateTime local cùng khoảnh khắc) trên MỌI timezone.
      final displayed = DateTimeUtils.formatDateTime(
        DataConverter.cvToDateTime(utcIso),
      );
      final expected = DateFormat('dd/MM/yyyy HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(
          DateTime.parse(utcIso).millisecondsSinceEpoch,
        ),
      );

      expect(displayed, equals(expected));
    });

    test('whitespace-padded and invalid strings handled safely', () {
      expect(
        DataConverter.cvToDateTime('  $utcIso  '),
        equals(DateTime.parse(utcIso).toLocal()),
      );
      expect(DataConverter.cvToDateTime(''), isNull);
      expect(DataConverter.cvToDateTime('   '), isNull);
      expect(DataConverter.cvToDateTime('not_a_timestamp'), isNull);
      expect(DataConverter.cvToDateTime('invalid', DateTime(2026)), isNotNull);
    });
  });
}
