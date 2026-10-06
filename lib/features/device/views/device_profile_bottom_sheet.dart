import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/bottom_sheet_utils.dart';
import '../bloc/device_profile_cubit.dart';
import '../bloc/device_setup_bloc.dart';
import 'device_health_section.dart';
import 'device_info_card.dart';
import 'device_preferences_section.dart';

/// Modal BottomSheet quản lý hồ sơ & thiết lập thiết bị.
/// Tổ chức thành 3 section độc lập: Thông tin thiết bị, Tình trạng hoạt động và Cài đặt tùy chọn.
class DeviceProfileBottomSheet extends StatelessWidget {
  const DeviceProfileBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final setupBloc = context.read<DeviceSetupBloc>();
    final profileCubit = context.read<DeviceProfileCubit>();
    return BottomSheetUtils.showBaseForm(
      context: context,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: setupBloc),
          BlocProvider.value(value: profileCubit),
        ],
        child: const DeviceProfileBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Card thông tin thiết bị (Tên + ID + Sửa tên)
          DeviceInfoCard(),
          SizedBox(height: 16),

          // 2. Tình trạng hoạt động (Quyền SMS + Chạy nền + Shortcut kiểm tra)
          DeviceHealthSection(),
          SizedBox(height: 16),

          // 3. Tùy chọn giao diện & Bộ lọc
          DevicePreferencesSection(),
        ],
      ),
    );
  }
}
