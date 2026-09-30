import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/pairing/presentation/bloc/pairing_bloc.dart';
import 'features/receiver/presentation/bloc/receiver_bloc.dart';
import 'features/role_selection/presentation/pages/role_selection_page.dart';
import 'features/sender/presentation/bloc/sender_bloc.dart';

class OtpRelayApp extends StatelessWidget {
  const OtpRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final di = DependencyContainer.instance;

    return ToastificationWrapper(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<SenderBloc>(
            create: (_) => SenderBloc(repository: di.senderRepository),
          ),
          BlocProvider<PairingBloc>(
            create: (_) => PairingBloc(repository: di.pairingRepository),
          ),
          BlocProvider<ReceiverBloc>(
            create: (_) => ReceiverBloc(repository: di.receiverRepository),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: AppStrings.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: const RoleSelectionPage(),
            );
          },
        ),
      ),
    );
  }
}
