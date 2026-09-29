import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/app.dart';
import 'package:sms_navigator/core/constants/app_strings.dart';
import 'package:sms_navigator/core/di/injection.dart';

void main() {
  setUp(() {
    DependencyContainer.instance.init();
  });

  testWidgets('App displays Role Selection with Sender and Receiver options',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OtpRelayApp());
    await tester.pumpAndSettle();

    // Verify Title and Subtitle are displayed
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.roleSelectionSubtitle), findsOneWidget);

    // Verify Role Cards are present
    expect(find.text(AppStrings.roleSenderTitle), findsOneWidget);
    expect(find.text(AppStrings.roleReceiverTitle), findsOneWidget);
  });
}
