import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/main_navigation_page.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_state.dart';
import 'splash_branding_view.dart';
import 'splash_error_view.dart';
import 'splash_progress_view.dart';
import 'splash_setup_choice_view.dart';

/// View chính của Splash, quản lý điều hướng khi sẵn sàng và hiển thị các sub-views theo trạng thái.
class SplashView extends StatelessWidget {
  final VoidCallback? onCompleted;

  const SplashView({super.key, this.onCompleted});

  void _navigateToMain(BuildContext context) {
    if (onCompleted != null) {
      onCompleted!();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state.isReady) {
          _navigateToMain(context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // App Logo Hero & Tiêu đề thương hiệu
                    const SplashBrandingView(),

                    const Spacer(flex: 2),

                    // Lần mở đầu: chọn thiết lập mới / khôi phục (BACKLOG 1.1),
                    // trạng thái tiến trình, hoặc khối báo lỗi
                    if (state.isAwaitingSetupChoice) ...[
                      const SplashSetupChoiceView(),
                    ] else if (!state.isFailure) ...[
                      SplashProgressView(status: state.status),
                    ] else ...[
                      SplashErrorView(
                        errorMessage: state.errorMessage,
                        failureKind: state.failureKind,
                      ),
                    ],

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
