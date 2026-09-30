import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/extensions/context_extensions.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

void main() {
  testWidgets('ContextExtensions provides l10n, theme, and colorScheme', (
    tester,
  ) async {
    late AppLocalizations l10n;
    late ThemeData theme;
    late ColorScheme colorScheme;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            theme = context.theme;
            colorScheme = context.colorScheme;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(l10n.appTitle, equals('OTP Relay'));
    expect(theme.brightness, equals(Brightness.light));
    expect(colorScheme.brightness, equals(Brightness.light));
  });
}
