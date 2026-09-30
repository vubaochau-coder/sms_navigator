import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import 'core/constants/app_strings.dart';
import 'core/services/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/utils/dialog_utils.dart';
import 'features/home/presentation/pages/main_navigation_page.dart';
import 'features/pairing/data/repositories/pairing_repository.dart';
import 'features/pairing/presentation/bloc/pairing_bloc.dart';
import 'l10n/app_localizations.dart';

class OtpRelayApp extends StatelessWidget {
  const OtpRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.read<AnalyticsService>();

    return ToastificationWrapper(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<PairingBloc>(
            create: (ctx) => PairingBloc(
              repository: ctx.read<PairingRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              navigatorKey: DialogUtils.navigatorKey,
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
              home: const MainNavigationPage(),
            );
          },
        ),
      ),
    );
  }
}
