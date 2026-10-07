import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import 'core/constants/app_strings.dart';
import 'core/navigation/app_navigator.dart';
import 'core/observers/app_lifecycle_observer.dart';
import 'core/services/analytics_service.dart';
import 'core/services/sync_owner_relay_channel_use_case.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/splash/splash_page.dart';
import 'l10n/app_localizations.dart';

class OtpRelayApp extends StatefulWidget {
  final Widget? home;

  const OtpRelayApp({super.key, this.home});

  @override
  State<OtpRelayApp> createState() => _OtpRelayAppState();
}

class _OtpRelayAppState extends State<OtpRelayApp> {
  AppLifecycleObserver? _lifecycleObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lifecycleObserver == null) {
      try {
        final syncUseCase = context.read<SyncOwnerRelayChannelUseCase>();
        _lifecycleObserver = AppLifecycleObserver(syncUseCase: syncUseCase)..register();
        // Initial sync on startup
        syncUseCase().catchError((_) => false);
      } catch (_) {
        // Fallback for tests if provider is omitted
      }
    }
  }

  @override
  void dispose() {
    _lifecycleObserver?.unregister();
    super.dispose();
  }

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
            home: widget.home ?? const SplashPage(),
          );
        },
      ),
    );
  }
}
