import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/services/analytics_service.dart';
import 'package:sms_navigator/core/services/crashlytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashlyticsService Tests', () {
    test('instance returns singleton', () {
      final instance1 = CrashlyticsService.instance;
      final instance2 = CrashlyticsService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test(
      'methods gracefully handle offline/uninitialized Firebase without crashing',
      () async {
        final crashlytics = CrashlyticsService.instance;

        // When Firebase.apps is empty (typical in unit test environment):
        await crashlytics.initialize();
        expect(crashlytics.isInitialized, isFalse);

        // Should not throw any exception
        await crashlytics.recordError(
          'Sample non-fatal error',
          StackTrace.current,
        );
        await crashlytics.log('Sample breadcrumb log');
        await crashlytics.setCustomKey('test_key', 'test_value');
        await crashlytics.setUserId('device_123');
      },
    );
  });

  group('AnalyticsService Tests', () {
    test('instance returns singleton', () {
      final instance1 = AnalyticsService.instance;
      final instance2 = AnalyticsService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test(
      'methods gracefully handle offline/uninitialized Firebase without crashing',
      () async {
        final analytics = AnalyticsService.instance;

        analytics.initialize();
        expect(analytics.isAvailable, isFalse);
        expect(analytics.observer, isNull);

        // Should not throw any exception
        await analytics.logEvent('test_event', parameters: {'param': 'val'});
        await analytics.logRoleSelected('SENDER');
        await analytics.logPairDeviceSuccess(
          role: 'RECEIVER',
          pairId: 'pair_456',
        );
        await analytics.logOtpRelayed(senderPhone: '19001234', otpLength: 6);
        await analytics.logRelayToggled(true);
        await analytics.logRelayModeChanged('OTP_ONLY');
        await analytics.logServerUrlUpdated('https://api.example.com');
        await analytics.setUserId('user_789');
      },
    );
  });
}
