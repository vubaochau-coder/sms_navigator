import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import 'core/constants/app_strings.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/splash/splash_page.dart';
import 'l10n/app_localizations.dart';

class OtpRelayApp extends StatelessWidget {
  final Widget? home;

  const OtpRelayApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    final analytics = context.read<AnalyticsService>();

    return ToastificationWrapper(
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            navigatorKey: AppNavigator.key,
            title: AppStrings.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            navigatorObservers: [
              if (analytics.observer != null) analytics.observer!,
            ],
            home: home ?? const SplashPage(),
          );
        },
      ),
    );
  }
}
