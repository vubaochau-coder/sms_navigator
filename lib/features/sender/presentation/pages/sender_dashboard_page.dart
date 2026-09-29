import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../../notification_test/presentation/pages/notification_test_page.dart';
import '../../../otp_list/presentation/pages/otp_list_page.dart';
import '../../../pairing/presentation/pages/paired_receivers_page.dart';
import '../../../pairing/presentation/pages/pairing_sender_page.dart';
import '../../data/models/relay_log_model.dart';
import '../bloc/sender_bloc.dart';
import '../bloc/sender_event.dart';
import '../bloc/sender_state.dart';

class SenderDashboardPage extends StatefulWidget {
  const SenderDashboardPage({super.key});

  @override
  State<SenderDashboardPage> createState() => _SenderDashboardPageState();
}

class _SenderDashboardPageState extends State<SenderDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<SenderBloc>().add(const SenderLoadStatusEvent());
    _checkSmsPermission();
  }

  Future<void> _checkSmsPermission() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
  }

  void _showServerSettingsDialog() {
    final di = DependencyContainer.instance;
    showDialog(
      context: context,
      builder: (_) => ServerSettingsDialog(
        deviceStorageService: di.deviceStorageService,
        nativeRelayService: di.nativeRelayService,
      ),
    );
  }

  Future<void> _showSimulateOtpDialog() async {
    final di = DependencyContainer.instance;
    final config = await di.nativeRelayService.getRelayConfig();
    final pairId = config['pairId']?.toString();
    final secret = config['sharedSecretBase64']?.toString();

    if (pairId == null || pairId.isEmpty || secret == null || secret.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng ghép đôi thiết bị trước khi thử nghiệm.'),
        ),
      );
      return;
    }

    final senderController = TextEditingController(text: 'Vietcombank');
    final otpController = TextEditingController(
      text: (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString(),
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.send_to_mobile_rounded),
              SizedBox(width: 8),
              Text('Mô Phỏng Gửi OTP'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senderController,
                decoration: const InputDecoration(
                  labelText: 'Tên Ngân hàng / Dịch vụ',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mã OTP (6 chữ số)',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded),
              label: const Text('Gửi Relay'),
              onPressed: () async {
                final sName = senderController.text.trim();
                final otpVal = otpController.text.trim();
                if (otpVal.isEmpty) return;

                Navigator.pop(dialogCtx);
                try {
                  final encrypted = await CryptoHelper.encryptAesGcm256(
                    plaintext: jsonEncode({
                      'sender': sName,
                      'otp': otpVal,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                    }),
                    secretKeyBase64: secret,
                  );

                  final deviceId =
                      await di.deviceStorageService.getDeviceId() ?? 'dev_sender';
                  await di.apiClient.post(
                    ApiEndpoints.relay,
                    body: {
                      'pair_id': pairId,
                      'device_id': deviceId,
                      'encrypted_payload': encrypted['ciphertext']!,
                      'iv': encrypted['iv']!,
                      'sent_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      'ttl_seconds': 300,
                    },
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã gửi mã OTP $otpVal thành công sang máy nhận!'),
                      ),
                    );
                    context
                        .read<SenderBloc>()
                        .add(const SenderLoadStatusEvent());
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi gửi OTP: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Máy Gửi (Việt Nam)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices_rounded),
            tooltip: 'Danh sách thiết bị nhận',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairedReceiversPage()),
              );
            },
          ),
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
          IconButton(
            icon: const Icon(Icons.send_to_mobile_rounded),
            tooltip: 'Mô phỏng gửi OTP',
            onPressed: _showSimulateOtpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.dns_rounded),
            tooltip: 'Cài đặt Server',
            onPressed: _showServerSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SenderBloc>().add(const SenderLoadStatusEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<SenderBloc, SenderState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SenderBloc>().add(const SenderLoadStatusEvent());
            },
            child: ListView(
              padding: Dimens.screenPadding,
              children: [
                _StatusCard(state: state),
                const SizedBox(height: 16),
                if (!state.isBatteryOptimizationIgnored) ...[
                  _BatteryOptimizationBanner(
                    onRequest: () {
                      context
                          .read<SenderBloc>()
                          .add(const SenderRequestBatteryOptimizationEvent());
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                _PairingCard(state: state),
                const SizedBox(height: 16),
                _FilterConfigCard(state: state),
                const SizedBox(height: 16),
                _RecentLogsSection(logs: state.logs),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Thẻ trạng thái chuyển tiếp — Soft Modern.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final SenderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = state.isRelayEnabled && state.isPaired;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.success : colorScheme.outline,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.success
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'ĐANG CHUYỂN TIẾP NGẦM' : 'TẠM DỪNG HOẠT ĐỘNG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isActive
                          ? AppColors.success
                          : colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: state.isRelayEnabled,
                activeTrackColor: AppColors.success,
                onChanged: state.isPaired
                    ? (val) {
                        context.read<SenderBloc>().add(SenderToggleRelayEvent(val));
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isActive
                ? 'App đang tự động bắt SMS OTP và chuyển tiếp sang Máy Nhận qua kết nối mã hóa E2EE.'
                : (state.isPaired
                    ? 'Bật công tắc phía trên để bắt đầu chuyển tiếp OTP.'
                    : 'Thiết bị chưa được ghép đôi. Vui lòng ghép đôi với Máy Nhận để kích hoạt.'),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (state.lastDetectedOtp != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vừa bắt được OTP: ${state.lastDetectedOtp} (từ ${state.lastDetectedSender})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner cảnh báo tối ưu pin — Soft Modern.
class _BatteryOptimizationBanner extends StatelessWidget {
  const _BatteryOptimizationBanner({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.battery_alert, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Text(
                'Cho phép chạy ngầm (Quan trọng)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống Android (đặc biệt là Xiaomi, Samsung, Oppo) có thể tắt app khi tắt màn hình. Cần tắt tối ưu pin để nhận SMS liên tục.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: onRequest,
            child: const Text('Bật Chạy Ngầm Ngay', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Thẻ thông tin ghép đôi — Soft Modern.
class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.state});

  final SenderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông Tin Ghép Đôi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
              if (state.isPaired)
                TextButton(
                  onPressed: () {
                    _UnpairDialog.show(context);
                  },
                  child: Text(
                    'Hủy Ghép Đôi',
                    style: TextStyle(color: colorScheme.error, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.isPaired) ...[
            _InfoRow(
              label: 'Mã Kênh (Pair ID):',
              value: state.pairId,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: 'ID Thiết Bị:',
              value: state.deviceId.substring(0, 8),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.devices_rounded, size: 18),
                label: const Text('Quản lý thiết bị nhận (Bật/Tắt gửi)'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PairedReceiversPage()),
                  );
                },
              ),
            ),
          ] else ...[
            Text(
              'Chưa có thiết bị Malaysia nào được kết nối với máy này.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('Tạo Mã Ghép Đôi'),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PairingSenderPage(),
                    ),
                  );
                  if (!context.mounted) return;
                  context.read<SenderBloc>().add(const SenderLoadStatusEvent());
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog xác nhận hủy ghép đôi.
class _UnpairDialog {
  static void show(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy Ghép Đôi?'),
        content: const Text(
          'Thiết bị sẽ ngừng chuyển tiếp OTP đến Máy Nhận. Bạn có chắc chắn muốn hủy không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Giữ Lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<SenderBloc>().add(const SenderUnpairEvent());
            },
            child: const Text('Hủy Ghép Đôi'),
          ),
        ],
      ),
    );
  }
}

/// Một dòng thông tin label — value trong thẻ ghép đôi.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Danh sách nhật ký chuyển tiếp gần đây — Soft Modern.
class _RecentLogsSection extends StatelessWidget {
  const _RecentLogsSection({required this.logs});

  final List<RelayLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhật Ký Chuyển Tiếp Gần Đây',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Center(
              child: Text(
                'Chưa có hoạt động chuyển tiếp OTP nào.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              final timeStr = DateFormat('HH:mm:ss dd/MM').format(
                DateTime.fromMillisecondsSinceEpoch(log.timestamp),
              );

              return _RelayLogTile(log: log, timeStr: timeStr);
            },
          ),
      ],
    );
  }
}

/// Một dòng nhật ký chuyển tiếp — Soft Modern.
class _RelayLogTile extends StatelessWidget {
  const _RelayLogTile({required this.log, required this.timeStr});

  final RelayLogModel log;
  final String timeStr;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuccess = log.status == 'SUCCESS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.successLight : AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.warning_amber_rounded,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.sender,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'OTP: ${log.otp.length > 2 ? "${log.otp.substring(0, 2)}****" : log.otp}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ cấu hình bộ lọc SMS & đầu số Whitelist.
class _FilterConfigCard extends StatefulWidget {
  const _FilterConfigCard({required this.state});

  final SenderState state;

  @override
  State<_FilterConfigCard> createState() => _FilterConfigCardState();
}

class _FilterConfigCardState extends State<_FilterConfigCard> {
  final TextEditingController _prefixController = TextEditingController();

  final List<Map<String, String>> _quickPresets = [
    {'label': '+86 (TQ)', 'value': '+86'},
    {'label': '1069 (SMS TQ)', 'value': '1069'},
    {'label': '955xx (Bank TQ)', 'value': '955'},
    {'label': '+84 (VN)', 'value': '+84'},
    {'label': '195 (Viettel)', 'value': '195'},
  ];

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  void _addPrefix(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    context.read<SenderBloc>().add(SenderAddWhitelistPrefixEvent(clean));
    _prefixController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMode = widget.state.relayMode;
    final whitelist = widget.state.senderWhitelist;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bộ Lọc & Đầu Số Chuyển Tiếp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Hỗ trợ OTP tiếng Trung & Chuyển tiếp toàn bộ SMS theo đầu số',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chế độ chuyển tiếp
          Text(
            'CHẾ ĐỘ CHUYỂN TIẾP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            context: context,
            title: 'Chỉ tin nhắn OTP (VN, EN, CN)',
            subtitle: 'Tự động nhận diện mã xác thực tiếng Việt, Anh và tiếng Trung (验证码, 动态码, 校验码...)',
            modeValue: 'OTP_ONLY',
            currentMode: currentMode,
            icon: Icons.pin_outlined,
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            context: context,
            title: 'Toàn bộ SMS từ Đầu số Whitelist',
            subtitle: 'Chuyển tiếp 100% nội dung SMS của các số điện thoại/đầu số trong danh sách',
            modeValue: 'WHITELIST_ALL',
            currentMode: currentMode,
            icon: Icons.format_list_bulleted_rounded,
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            context: context,
            title: 'Chuyển tiếp tất cả SMS (Forward All)',
            subtitle: 'Chuyển tiếp mọi tin nhắn SMS nhận được sang thiết bị đã ghép đôi',
            modeValue: 'ALL_SMS',
            currentMode: currentMode,
            icon: Icons.all_inclusive_rounded,
          ),
          // Phần cấu hình whitelist chi tiết (hiển thị khi chọn WHITELIST_ALL)
          if (currentMode == 'WHITELIST_ALL') ...[
            const Divider(height: 28),
            Text(
              'DANH SÁCH ĐẦU SỐ / SỐ ĐIỆN THOẠI ÁP DỤNG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            // Quick preset chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickPresets.map((preset) {
                final isAdded = whitelist.contains(preset['value']);
                return ActionChip(
                  avatar: Icon(
                    isAdded ? Icons.check_circle : Icons.add_circle_outline,
                    size: 16,
                    color: isAdded ? AppColors.success : colorScheme.primary,
                  ),
                  label: Text(preset['label']!, style: const TextStyle(fontSize: 12)),
                  onPressed: isAdded ? null : () => _addPrefix(preset['value']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prefixController,
                    decoration: InputDecoration(
                      hintText: 'Nhập số, đầu số (VD: +86, 1069...)',
                      hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: _addPrefix,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => _addPrefix(_prefixController.text),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Whitelist chips list
            if (whitelist.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chưa có đầu số nào. Hãy bấm các nút gợi ý nhanh ở trên hoặc nhập đầu số cụ thể.',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: whitelist.map((item) {
                  return Chip(
                    label: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      context
                          .read<SenderBloc>()
                          .add(SenderRemoveWhitelistPrefixEvent(item));
                    },
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    side: BorderSide(color: colorScheme.outlineVariant),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String modeValue,
    required String currentMode,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = currentMode == modeValue;

    return InkWell(
      onTap: () {
        context.read<SenderBloc>().add(SenderUpdateRelayModeEvent(modeValue));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(20)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
