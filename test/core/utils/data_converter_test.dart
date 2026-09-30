import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/data_converter.dart';

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
}
