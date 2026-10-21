import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/utils/bounded_concurrency.dart';

void main() {
  test('runs every item and never more than the limit at once', () async {
    var running = 0;
    var peak = 0;
    final done = <int>[];

    await forEachBounded<int>(
      List.generate(10, (i) => i),
      (i) async {
        running++;
        peak = running > peak ? running : peak;
        await Future<void>.delayed(const Duration(milliseconds: 2));
        done.add(i);
        running--;
      },
      concurrency: 3,
    );

    expect(done..sort(), List.generate(10, (i) => i));
    expect(peak, 3);
  });

  test('empty input completes immediately', () async {
    await forEachBounded<int>(const [], (_) async => fail('should not run'));
  });

  test('a failing item does not stop the others; the first error is rethrown', () async {
    final done = <int>[];
    await expectLater(
      forEachBounded<int>([1, 2, 3], (i) async {
        if (i == 2) throw StateError('boom');
        done.add(i);
      }, concurrency: 1),
      throwsStateError,
    );
    expect(done, [1, 3]);
  });
}
