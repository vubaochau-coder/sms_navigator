import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/pairing/presentation/widgets/refreshable_empty_state.dart';

void main() {
  testWidgets(
    'RefreshableEmptyState triggers onRefresh when pulled while empty',
    (tester) async {
      int refreshCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshableEmptyState(
              onRefresh: () async {
                refreshCount++;
              },
              child: const Center(child: Text('Danh sách trống')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Danh sách trống'), findsOneWidget);
      expect(refreshCount, 0);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        2000,
      );
      await tester.pumpAndSettle();

      expect(refreshCount, 1);
    },
  );
}
