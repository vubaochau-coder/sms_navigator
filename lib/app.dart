import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/pairing/presentation/bloc/pairing_bloc.dart';
import 'features/receiver/presentation/bloc/receiver_bloc.dart';
import 'features/role_selection/presentation/pages/role_selection_page.dart';
import 'features/sender/presentation/bloc/sender_bloc.dart';

class OtpRelayApp extends StatelessWidget {
  const OtpRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final di = DependencyContainer.instance;

    return MultiBlocProvider(
      providers: [
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
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const RoleSelectionPage(),
      ),
    );
  }
}
