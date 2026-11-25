import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/splash/bloc/splash_state.dart';
import 'package:sms_navigator/features/splash/views/splash_error_view.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('serverStarting shows the browser wake button; returning to the app retries', (tester) async {
    var retries = 0;
    var opened = 0;
    await tester.pumpWidget(_host(SplashErrorView(
      errorMessage: 'asleep',
      failureKind: SplashFailureKind.serverStarting,
      onRetry: () => retries++,
      onWakeInBrowser: () async {
        opened++;
        return true;
      },
    )));

    await tester.tap(find.text('Đánh thức bằng trình duyệt'));
    await tester.pump();
    expect(opened, 1);
    expect(retries, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(retries, 1);

    // A later resume without opening the browser again does not retry.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('other failures have no browser wake button', (tester) async {
    await tester.pumpWidget(_host(SplashErrorView(
      errorMessage: 'boom',
      failureKind: SplashFailureKind.server,
      onRetry: () {},
    )));
    expect(find.text('Đánh thức bằng trình duyệt'), findsNothing);
  });
}
