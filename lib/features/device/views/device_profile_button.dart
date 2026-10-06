import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../bloc/device_profile_cubit.dart';
import '../bloc/device_profile_state.dart';
import '../bloc/device_setup_bloc.dart';
import '../bloc/device_setup_state.dart';
import '../device_profile_page.dart';

/// Nút hiển thị thông tin thiết bị dạng icon gọn trên AppBar (không show tên).
/// Chấm tròn nhỏ góc biểu tượng thể hiện trạng thái hoạt động (🟢 Xanh = Đầy đủ quyền, 🟠 Vàng = Cần chú ý).
/// Bấm vào mở màn hình thiết lập để xem tên thiết bị, đổi tên, sao chép ID, kiểm tra quyền & theme.
class DeviceProfileButton extends StatelessWidget {
  const DeviceProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<DeviceProfileCubit, DeviceProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<DeviceSetupBloc, DeviceSetupState>(
          builder: (context, setupState) {
            final isAllOk = setupState.isAllCriticalStepsDone;
            final statusColor = isAllOk ? AppColors.success : AppColors.warning;

            return IconButton(
              tooltip: profileState.deviceName.isNotEmpty
                  ? profileState.deviceName
                  : 'Thông tin & Thiết lập thiết bị',
              onPressed: () {
                final setupBloc = context.read<DeviceSetupBloc>();
                final profileCubit = context.read<DeviceProfileCubit>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: setupBloc),
                        BlocProvider.value(value: profileCubit),
                      ],
                      child: const DeviceProfilePage(),
                    ),
                  ),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
