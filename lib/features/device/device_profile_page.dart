import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../backup/views/device_backup_section.dart';
import 'views/device_health_section.dart';
import 'views/device_info_card.dart';
import 'views/device_preferences_section.dart';

/// Trang quản lý hồ sơ & thiết lập thiết bị.
/// Tổ chức thành 4 section độc lập: Thông tin thiết bị, Tình trạng hoạt động, Sao lưu và Cài đặt tùy chọn.
class DeviceProfilePage extends StatelessWidget {
  const DeviceProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deviceProfileTitle),
      ),
      body: const SingleChildScrollView(
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

            // 3. Sao lưu danh tính & khoá (BACKLOG 1.1)
            DeviceBackupSection(),
            SizedBox(height: 16),

            // 4. Tùy chọn giao diện & Bộ lọc
            DevicePreferencesSection(),
          ],
        ),
      ),
    );
  }
}
