import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../notification_test/presentation/pages/notification_test_page.dart';
import '../../../otp_list/presentation/pages/otp_list_page.dart';
import '../../../receiver/presentation/pages/receiver_dashboard_page.dart';
import '../../../sender/presentation/pages/sender_dashboard_page.dart';
import '../widgets/role_card.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Danh sách OTP theo ngày',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OtpListPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Thử nghiệm Thông Báo Push',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationTestPage()),
              );
            },
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Dimens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 18),
              const _AppLogo(),
              const SizedBox(height: 24),
              Text(
                AppStrings.roleSelectionTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.roleSelectionSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              RoleCard(
                title: AppStrings.roleSenderTitle,
                description: AppStrings.roleSenderDesc,
                badge: 'Thiết Bị Gốc',
                icon: Icons.sim_card_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SenderDashboardPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              RoleCard(
                title: AppStrings.roleReceiverTitle,
                description: AppStrings.roleReceiverDesc,
                badge: 'Thiết Bị Đích',
                icon: Icons.phonelink_ring_outlined,
                color: theme.colorScheme.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReceiverDashboardPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Thử Nghiệm & Xem UI Push Notification'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationTestPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bảo mật E2EE • Server không thể đọc OTP',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.sync_alt_rounded, color: Colors.white, size: 38),
    );
  }
}


